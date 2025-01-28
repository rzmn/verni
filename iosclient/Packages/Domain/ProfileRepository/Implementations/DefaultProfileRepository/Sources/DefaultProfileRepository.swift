import AsyncExtensions
import ProfileRepository
import InfrastructureLayer
import Logging
import Entities
import Api
import SyncEngine
import PersistentStorage
internal import Convenience

public actor DefaultProfileRepository: Sendable {
    public let logger: Logger
    
    private let api: APIProtocol
    private let sync: Engine
    private let reducer: Reducer
    private let userId: User.Identifier
    private let updatesSubject: AsyncSubject<Profile>
    private let infrastructure: InfrastructureLayer
    private var state: State
    private var remoteUpdatesSubscription: BlockAsyncSubscription<[Components.Schemas.Operation]>?
    
    public init(
        infrastructure: InfrastructureLayer,
        userId: User.Identifier,
        api: APIProtocol,
        sync: Engine,
        logger: Logger
    ) async {
        await self.init(
            reducer: DefaultReducer(
                verifyEmailReducer: VerifyEmailReducer,
                updateEmailReducer: UpdateEmailReducer
            ),
            infrastructure: infrastructure,
            userId: userId,
            api: api,
            sync: sync,
            logger: logger
        )
    }
    
    init(
        reducer: @escaping Reducer,
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
    public nonisolated var updates: any AsyncBroadcast<Profile> {
        updatesSubject
    }
    
    public var profile: Profile {
        get async {
            state.profile.value ?? Profile(
                userId: userId,
                email: .undefined
            )
        }
    }
    
    public func updateEmail(_ email: String) async throws(EmailUpdateError) {
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
            throw EmailUpdateError(error: error)
        }
        let startupData: Components.Schemas.StartupData
        do {
            startupData = try response.get()
        } catch {
            switch error {
            case .expected(let error):
                logW { "update email finished with error: \(error)" }
                throw EmailUpdateError(error: error)
            case .undocumented(let statusCode, let payload):
                logE { "update email undocumented response code: \(statusCode), payload: \(payload)" }
                throw EmailUpdateError(error: error)
            }
        }
        do {
            try await sync.pulled(operations: startupData.operations)
        } catch {
            logE { "updateEmail: failed to handle startup data error: \(error)" }
            throw .other(.other(error))
        }
    }
    
    public func updatePassword(old: String, new: String) async throws(PasswordUpdateError) {
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
            throw PasswordUpdateError(error: error)
        }
        let startupData: Components.Schemas.StartupData
        do {
            startupData = try response.get()
        } catch {
            switch error {
            case .expected(let error):
                logW { "update password finished with error: \(error)" }
                throw PasswordUpdateError(error: error)
            case .undocumented(let statusCode, let payload):
                logE { "update password undocumented response code: \(statusCode), payload: \(payload)" }
                throw PasswordUpdateError(error: error)
            }
        }
        do {
            try await sync.pulled(operations: startupData.operations)
        } catch {
            logE { "updateEmail: failed to handle startup data error: \(error)" }
            throw .other(.other(error))
        }
    }
}

extension DefaultProfileRepository: Loggable {}
