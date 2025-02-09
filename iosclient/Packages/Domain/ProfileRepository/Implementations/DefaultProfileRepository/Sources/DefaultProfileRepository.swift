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
    private let eventPublisher: EventPublisher<Profile>
    private let infrastructure: InfrastructureLayer
    private var state: State
    
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
        self.eventPublisher = EventPublisher()
        for operation in await sync.operations {
            state = reducer(operation, state)
        }
        await sync.updates.subscribeWeak(self) { [weak self] operations in
            guard let self else { return }
            infrastructure.taskFactory.task { [weak self] in
                guard let self else { return }
                await received(operations: operations)
            }
        }
    }
    
    private func received(operation: Components.Schemas.SomeOperation) {
        received(operations: [operation])
    }
    
    private func received(operations: [Components.Schemas.SomeOperation]) {
        let oldState = state
        for operation in operations {
            state = reducer(operation, state)
        }
        guard let profile = state.profile.value, oldState.profile.value != profile else {
            return
        }
        infrastructure.taskFactory.detached { [weak self] in
            guard let self else { return }
            await eventPublisher.notify(profile)
        }
    }
}

extension DefaultProfileRepository: ProfileRepository {
    public nonisolated var updates: any EventSource<Profile> {
        eventPublisher
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
        do {
            _ = try response.get()
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
        do {
            _ = try response.get()
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
    }
}

extension DefaultProfileRepository: Loggable {}
