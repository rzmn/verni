import Api
import AsyncExtensions
internal import Convenience
import Entities
import InfrastructureLayer
import Logging
import PersistentStorage
import SyncEngine
import UsersRepository

public actor DefaultUsersRepository: Sendable {
    public let logger: Logger
    private let infrastructure: InfrastructureLayer
    private let reducer: Reducer
    private var state: State
    private let sync: Engine
    private let userId: User.Identifier
    private let eventPublisher: EventPublisher<[User.Identifier: AnyUser]>

    public init(
        userId: User.Identifier,
        sync: Engine,
        infrastructure: InfrastructureLayer,
        logger: Logger
    ) async {
        await self.init(
            reducer: DefaultReducer(
                createUserReducer: CreateUserReducer,
                updateDisplayNameReducer: UpdateDisplayNameReducer,
                updateAvatarReducer: UpdateAvatarReducer,
                bindUserReducer: BindUserReducer
            ),
            userId: userId,
            sync: sync,
            infrastructure: infrastructure,
            logger: logger
        )
    }
    
    init(
        reducer: @escaping Reducer,
        userId: User.Identifier,
        sync: Engine,
        infrastructure: InfrastructureLayer,
        logger: Logger
    ) async {
        self.logger = logger
        self.state = State(users: [:])
        self.reducer = reducer
        self.infrastructure = infrastructure
        self.sync = sync
        self.userId = userId
        eventPublisher = EventPublisher()
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
        let updates = state.users.reduce(into: [:] as [User.Identifier: AnyUser]) { dict, kv in
            let (userId, user) = kv
            guard let value = user.value else {
                return
            }
            guard oldState.users[userId]?.value != value else {
                return
            }
            dict[userId] = value
        }
        guard !updates.isEmpty else {
            return
        }
        infrastructure.taskFactory.detached { [weak self] in
            guard let self else { return }
            await eventPublisher.notify(updates)
        }
    }
}

extension DefaultUsersRepository: UsersRepository {
    private var isUserIdReserved: (User.Identifier) -> Bool {
        state.users.keys.contains
    }

    private var isOperationIdReserved: (SpendingGroup.Identifier) -> Bool {
        get async {
            Set(await sync.operations.map(\.value1.operationId)).contains
        }
    }

    public nonisolated var updates: any EventSource<[User.Identifier: AnyUser]> {
        eventPublisher
    }

    public subscript(id: User.Identifier) -> AnyUser? {
        get async {
            state.users[id]?.value
        }
    }

    public subscript(query: String) -> [AnyUser] {
        get async {
            state.users.values.compactMap(\.value).filter {
                $0.payload.displayName.contains(query)
            }
        }
    }

    public func createUser(
        displayName: String
    ) async throws(CreateUserError) -> User.Identifier {
        let userId = infrastructure.nextId(
            isBlacklisted: isUserIdReserved
        )
        let operation = await Components.Schemas.SomeOperation(
            value1: Components.Schemas.BaseOperation(
                operationId: infrastructure.nextId(
                    isBlacklisted: isOperationIdReserved
                ),
                createdAt: infrastructure.timeMs,
                authorId: userId
            ),
            value2: .CreateUserOperation(
                .init(
                    createUser: .init(
                        userId: userId,
                        displayName: displayName
                    )
                )
            )
        )
        do {
            try await sync.push(operation: operation)
        } catch {
            logE { "createUser: push failed error: \(error)" }
            throw .internal(error)
        }
        received(operation: operation)
        return userId
    }

    public func bind(
        localUserId: User.Identifier,
        to remoteUserId: User.Identifier
    ) async throws(BindUserError) {
        guard let anyUser = await self[localUserId] else {
            throw .userNotFound(localUserId)
        }
        guard case .sandbox(let user) = anyUser else {
            throw .notAllowed
        }
        if let alreadyBoundTo = user.boundTo {
            throw .alreadyBound(to: alreadyBoundTo)
        }
        guard let userToBound = await self[remoteUserId] else {
            throw .userNotFound(remoteUserId)
        }
        guard case .regular = userToBound else {
            throw .notAllowed
        }
        let operation = await Components.Schemas.SomeOperation(
            value1: Components.Schemas.BaseOperation(
                operationId: infrastructure.nextId(
                    isBlacklisted: isOperationIdReserved
                ),
                createdAt: infrastructure.timeMs,
                authorId: userId
            ),
            value2: .BindUserOperation(
                .init(
                    bindUser: .init(
                        oldId: localUserId,
                        newId: remoteUserId
                    )
                )
            )
        )
        do {
            try await sync.push(operation: operation)
        } catch {
            logE { "bind: push failed error: \(error)" }
            throw .internal(error)
        }
        return received(operation: operation)
    }

    public func updateDisplayName(
        userId: User.Identifier,
        displayName: String
    ) async throws(UpdateDisplayNameError) {
        guard let anyUser = await self[userId] else {
            throw .userNotFound(userId)
        }
        switch anyUser {
        case .sandbox(let user):
            guard user.ownerId == userId else {
                throw .notAllowed
            }
        case .regular(let user):
            guard user.id == userId else {
                throw .notAllowed
            }
        }
        let operation = await Components.Schemas.SomeOperation(
            value1: Components.Schemas.BaseOperation(
                operationId: infrastructure.nextId(
                    isBlacklisted: isOperationIdReserved
                ),
                createdAt: infrastructure.timeMs,
                authorId: userId
            ),
            value2: .UpdateDisplayNameOperation(
                .init(
                    updateDisplayName: .init(
                        userId: userId,
                        displayName: displayName
                    )
                )
            )
        )
        do {
            try await sync.push(operation: operation)
        } catch {
            logE { "updateDisplayName: push failed error: \(error)" }
            throw .internal(error)
        }
        return received(operation: operation)
    }

    public func updateAvatar(
        userId: User.Identifier,
        imageId: Image.Identifier
    ) async throws(UpdateAvatarError) {
        guard let anyUser = await self[userId] else {
            throw .userNotFound(userId)
        }
        switch anyUser {
        case .sandbox(let user):
            guard user.ownerId == userId else {
                throw .notAllowed
            }
        case .regular(let user):
            guard user.id == userId else {
                throw .notAllowed
            }
        }
        let operation = await Components.Schemas.SomeOperation(
            value1: Components.Schemas.BaseOperation(
                operationId: infrastructure.nextId(
                    isBlacklisted: isOperationIdReserved
                ),
                createdAt: infrastructure.timeMs,
                authorId: userId
            ),
            value2: .UpdateAvatarOperation(
                .init(
                    updateAvatar: .init(
                        userId: userId,
                        imageId: imageId
                    )
                )
            )
        )
        do {
            try await sync.push(operation: operation)
        } catch {
            logE { "updateAvatar: push failed error: \(error)" }
            throw .internal(error)
        }
        return received(operation: operation)
    }
}

extension DefaultUsersRepository: Loggable {}
