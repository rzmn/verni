import AsyncExtensions
import ProfileRepository
import InfrastructureLayer
import Logging
import Entities
import Api
import SyncEngine
import PersistentStorage
internal import Convenience

actor DefaultProfileRepository: Sendable {
    let logger: Logger
    
    private let api: APIProtocol
    private let sync: Engine
    private let reducer: Reducer
    private let userId: User.Identifier
    private let updatesSubject: AsyncSubject<Profile>
    private let infrastructure: InfrastructureLayer
    private var state: State
    private var remoteUpdatesSubscription: BlockAsyncSubscription<[Components.Schemas.Operation]>?
    
    init(
        reducer: @escaping Reducer = DefaultReducer(
            verifyEmailReducer: VerifyEmailReducer,
            updateEmailReducer: UpdateEmailReducer
        ),
        infrastructure: InfrastructureLayer,
        userId: User.Identifier,
        api: APIProtocol,
        sync: Engine,
        logger: Logger
    ) async {
        self.logger = logger
        self.userId = userId
        self.api = api
        self.sync = sync
        self.reducer = reducer
        self.state = State(
            profile: LastWriteWinsCRDT(
                initial: Profile(
                    userId: userId,
                    email: .undefined
                )
            )
        )
        self.infrastructure = infrastructure
        self.updatesSubject = AsyncSubject(
            taskFactory: infrastructure.taskFactory,
            logger: logger.with(
                prefix: "🆕"
            )
        )
        for operation in await sync.operations {
            state = reducer(operation, state)
        }
        remoteUpdatesSubscription = await sync.updates.subscribe { [weak self] operations in
            Task { [weak self] in
                await self?.received(operations: operations)
            }
        }
    }
    
    private func received(operation: Components.Schemas.Operation) {
        received(operations: [operation])
    }
    
    private func received(operations: [Components.Schemas.Operation]) {
        let oldState = state
        for operation in operations {
            state = reducer(operation, state)
        }
        guard let profile = state.profile.value, oldState.profile.value != profile else {
            return
        }
        infrastructure.taskFactory.detached { [weak self] in
            await self?.updatesSubject.yield(profile)
        }
    }
}

extension DefaultProfileRepository: ProfileRepository {
    nonisolated var updates: any AsyncBroadcast<Profile> {
        updatesSubject
    }
    
    var profile: Profile {
        get async {
            state.profile.value ?? Profile(
                userId: userId,
                email: .undefined
            )
        }
    }
    
    func updateEmail(_ email: String) async throws(EmailUpdateError) {
        let response: Operations.UpdateEmail.Output
        do {
            response = try await api.updateEmail(
                .init(
                    body: .json(
                        .init(
                            email: email
                        )
                    )
                )
            )
        } catch {
            if let noConnection = error.noConnection {
                throw .other(.noConnection(noConnection))
            } else {
                throw .other(.other(error))
            }
        }
        let startupData: Components.Schemas.StartupData
        switch response {
        case .ok(let payload):
            switch payload.body {
            case .json(let body):
                startupData = body.response
            }
        case .unauthorized(let payload):
            throw .other(.notAuthorized(ErrorContext(context: payload)))
        case .conflict(let payload):
            logI { "updateEmail failed due conflict: \(payload)" }
            throw .alreadyTaken
        case .unprocessableContent(let payload):
            logI { "updateEmail failed due format check fail: \(payload)" }
            throw .wrongFormat
        case .internalServerError(let payload):
            logE { "updateEmail: internal error: \(payload)" }
            throw .other(.other(ErrorContext(context: payload)))
        case .undocumented(let statusCode, let body):
            logE { "updateEmail: undocumented response: code \(statusCode) body: \(body)" }
            throw .other(.other(ErrorContext(context: body)))
        }
        do {
            try await handle(startupData: startupData)
        } catch {
            logE { "updateEmail: failed to handle startup data error: \(error)" }
            throw .other(.other(error))
        }
    }
    
    func updatePassword(old: String, new: String) async throws(PasswordUpdateError) {
        let response: Operations.UpdatePassword.Output
        do {
            response = try await api.updatePassword(
                .init(
                    body: .json(
                        .init(
                            old: old,
                            new: new
                        )
                    )
                )
            )
        } catch {
            if let noConnection = error.noConnection {
                throw .other(.noConnection(noConnection))
            } else {
                throw .other(.other(error))
            }
        }
        let startupData: Components.Schemas.StartupData
        switch response {
        case .ok(let payload):
            switch payload.body {
            case .json(let body):
                startupData = body.response
            }
        case .unauthorized(let payload):
            throw .other(.notAuthorized(ErrorContext(context: payload)))
        case .conflict(let payload):
            logI { "updatePassword failed due conflict: \(payload)" }
            throw .incorrectOldPassword
        case .unprocessableContent(let payload):
            logI { "updatePassword failed due format check fail: \(payload)" }
            throw .wrongFormat
        case .internalServerError(let payload):
            logE { "updatePassword: internal error: \(payload)" }
            throw .other(.other(ErrorContext(context: payload)))
        case .undocumented(let statusCode, let body):
            logE { "updatePassword: undocumented response: code \(statusCode) body: \(body)" }
            throw .other(.other(ErrorContext(context: body)))
        }
        do {
            try await handle(startupData: startupData)
        } catch {
            logE { "updateEmail: failed to handle startup data error: \(error)" }
            throw .other(.other(error))
        }
    }
    
    private func handle(startupData: Components.Schemas.StartupData) async throws {
        try await storage.update(
            refreshToken: startupData.session.refreshToken
        )
        try await storage.update(
            operations: startupData.operations.map {
                Operation(
                    kind: .pendingConfirm,
                    payload: $0
                )
            }
        )
    }
}

extension DefaultProfileRepository: Loggable {}
