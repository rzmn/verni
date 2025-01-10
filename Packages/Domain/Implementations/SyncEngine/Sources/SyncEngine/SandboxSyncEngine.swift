import Domain
import PersistentStorage
import AsyncExtensions
import Base
import Foundation
import Logging
import DataLayerDependencies
import Api
internal import ApiDomainConvenience

actor SandboxSyncEngine {
    private let data: AnonymousDataLayerSession
    private var state: State

    init(
        data: AnonymousDataLayerSession
    ) async throws {
        self.data = data
        state = State(
            spendingGroupsOrder: OrderedSequenceCRDT(initial: []),
            spendingGroups: [:],
            groupsParticipantsOrder: [:],
            groupsParticipants: [:],
            spendingsOrder: [:],
            spendings: [:],
            users: [:]
        )
        try await push(
            operations: data.storage.operations
        )
    }

    func push(operation: Components.Schemas.Operation) async throws {
        try await push(operations: [operation])
    }

    func push(operations: [Components.Schemas.Operation]) async throws {
        try await data.storage
            .update(operations: operations)
        for operation in operations {
            await apply(operation: operation)
        }
    }
}

extension SandboxSyncEngine {
    private func apply(operation: Components.Schemas.Operation) async {
        switch operation.value2 {
        case .CreateUserOperation(let payload):
            state = modify(state) {
                let userId = payload.createUser.userId
                let user = state.users[userId, default: user(
                    id: userId,
                    ownerId: operation.value1.authorId
                )]
                switch user {
                case .sandbox(let user):
                    $0.users[userId] = .sandbox(
                        user.byInserting(
                            operation: LastWriteWinsCRDT.Operation(
                                kind: .create(
                                    SandboxUser(
                                        id: userId,
                                        ownerId: operation.value1.authorId,
                                        payload: UserPayload(
                                            displayName: payload.createUser.displayName,
                                            avatar: nil
                                        ),
                                        bindedTo: nil
                                    )
                                ),
                                id: operation.value1.id,
                                timestamp: operation.value1.timestamp
                            )
                        )
                    )
                case .regular(let user):
                    $0.users[payload.createUser.userId] = .regular(
                        user.byInserting(
                            operation: LastWriteWinsCRDT.Operation(
                                kind: .create(
                                    User(
                                        id: userId,
                                        payload: UserPayload(
                                            displayName: payload.createUser.displayName,
                                            avatar: nil
                                        )
                                    )
                                ),
                                id: operation.value1.id,
                                timestamp: operation.value1.timestamp
                            )
                        )
                    )
                }
            }
        case .UpdateDisplayNameOperation(let payload):
            state = modify(state) {
                let userId = payload.updateDisplayName.userId
                let user = state.users[userId, default: user(
                    id: userId,
                    ownerId: operation.value1.authorId
                )]
                switch user {
                case .sandbox(let user):
                    $0.users[userId] = .sandbox(
                        user.byInserting(
                            operation: LastWriteWinsCRDT.Operation(
                                kind: .mutate({ user in
                                    modify(user) {
                                        $0.payload.displayName = payload.updateDisplayName.displayName
                                    }
                                }),
                                id: operation.value1.id,
                                timestamp: operation.value1.timestamp
                            )
                        )
                    )
                case .regular(let user):
                    $0.users[userId] = .regular(
                        user.byInserting(
                            operation: LastWriteWinsCRDT.Operation(
                                kind: .mutate({ user in
                                    modify(user) {
                                        $0.payload.displayName = payload.updateDisplayName.displayName
                                    }
                                }),
                                id: operation.value1.id,
                                timestamp: operation.value1.timestamp
                            )
                        )
                    )
                }
            }
        case .UpdateAvatarOperation(let payload):
            state = modify(state) {
                let userId = payload.updateAvatar.userId
                let user = state.users[userId, default: user(
                    id: userId,
                    ownerId: operation.value1.authorId
                )]
                switch user {
                case .sandbox(let user):
                    $0.users[userId] = .sandbox(
                        user.byInserting(
                            operation: LastWriteWinsCRDT.Operation(
                                kind: .mutate({ user in
                                    modify(user) {
                                        $0.payload.avatar = payload.updateAvatar.imageId
                                    }
                                }),
                                id: operation.value1.id,
                                timestamp: operation.value1.timestamp
                            )
                        )
                    )
                case .regular(let user):
                    $0.users[userId] = .regular(
                        user.byInserting(
                            operation: LastWriteWinsCRDT.Operation(
                                kind: .mutate({ user in
                                    modify(user) {
                                        $0.payload.avatar = payload.updateAvatar.imageId
                                    }
                                }),
                                id: operation.value1.id,
                                timestamp: operation.value1.timestamp
                            )
                        )
                    )
                }
            }
        case .BindUserOperation(let payload):
            state = modify(state) {
                let userId = payload.bindUser.oldId
                let user = state.users[userId, default: user(
                    id: userId,
                    ownerId: operation.value1.authorId
                )]
                switch user {
                case .sandbox(let user):
                    $0.users[userId] = .sandbox(
                        user.byInserting(
                            operation: LastWriteWinsCRDT.Operation(
                                kind: .mutate({ user in
                                    modify(user) {
                                        $0.bindedTo = payload.bindUser.newId
                                    }
                                }),
                                id: operation.value1.id,
                                timestamp: operation.value1.timestamp
                            )
                        )
                    )
                case .regular:
                    assertionFailure()
                }
            }
        case .CreateSpendingGroupOperation(let payload):
            state = modify(state) {
                let groupId = payload.createSpendingGroup.groupId
                let group = state.spendingGroups[groupId, default: LastWriteWinsCRDT(initial: nil)]
                $0.spendingGroups[groupId] = group.byInserting(
                    operation: LastWriteWinsCRDT.Operation(
                        kind: .create(
                            SpendingsGroup(
                                id: groupId,
                                name: payload.createSpendingGroup.displayName,
                                createdAt: operation.value1.timestamp
                            )
                        ),
                        id: operation.value1.id,
                        timestamp: operation.value1.timestamp
                    )
                )
                $0.spendingGroupsOrder = $0.spendingGroupsOrder.byInserting(
                    operation: OrderedSequenceCRDT.Operation(
                        kind: .insert(groupId),
                        id: operation.value1.id,
                        timestamp: operation.value1.timestamp
                    )
                )
            }
        case .DeleteSpendingGroupOperation(let payload):
            state = modify(state) {
                let groupId = payload.deleteSpendingGroup.groupId
                let group = state.spendingGroups[groupId, default: LastWriteWinsCRDT(initial: nil)]
                $0.spendingGroups[groupId] = group.byInserting(
                    operation: LastWriteWinsCRDT.Operation(
                        kind: .delete,
                        id: operation.value1.id,
                        timestamp: operation.value1.timestamp
                    )
                )
                $0.spendingGroupsOrder = $0.spendingGroupsOrder.byInserting(
                    operation: OrderedSequenceCRDT.Operation(
                        kind: .delete(groupId),
                        id: operation.value1.id,
                        timestamp: operation.value1.timestamp
                    )
                )
            }
        case .CreateSpendingOperation(let payload):
            state = modify(state) { state in
                let spendingId = payload.createSpending.spendingId
                let spending = state.spendings[spendingId, default: LastWriteWinsCRDT(initial: nil)]
                state.spendings[spendingId] = spending.byInserting(
                    operation: LastWriteWinsCRDT.Operation(
                        kind: .create(
                            Spending(
                                id: spendingId,
                                payload: Spending.Payload(
                                    name: payload.createSpending.name,
                                    currency: Currency(dto: payload.createSpending.currency),
                                    createdAt: operation.value1.timestamp,
                                    amount: Amount(dto: payload.createSpending.amount),
                                    shares: payload.createSpending.shares.map {
                                        Spending.Share(
                                            userId: $0.userId,
                                            amount: Amount(dto: $0.amount)
                                        )
                                    }
                                )
                            )
                        ),
                        id: operation.value1.id,
                        timestamp: operation.value1.timestamp
                    )
                )
                let spendingsOrder = state.spendingsOrder[payload.createSpending.groupId, default: OrderedSequenceCRDT(initial: [])]
                state.spendingsOrder[payload.createSpending.groupId] = spendingsOrder.byInserting(
                    operation: OrderedSequenceCRDT.Operation(
                        kind: .insert(spendingId),
                        id: operation.value1.id,
                        timestamp: operation.value1.timestamp
                    )
                )
            }
        case .DeleteSpendingOperation(let payload):
            state = modify(state) {
                let spendingId = payload.deleteSpending.spendingId
                let spending = state.spendings[spendingId, default: LastWriteWinsCRDT(initial: nil)]
                $0.spendings[spendingId] = spending.byInserting(
                    operation: LastWriteWinsCRDT.Operation(
                        kind: .delete,
                        id: operation.value1.id,
                        timestamp: operation.value1.timestamp
                    )
                )
                let spendingsOrder = state.spendingsOrder[payload.deleteSpending.groupId, default: OrderedSequenceCRDT(initial: [])]
                $0.spendingsOrder[payload.deleteSpending.groupId] = spendingsOrder.byInserting(
                    operation: OrderedSequenceCRDT.Operation(
                        kind: .delete(spendingId),
                        id: operation.value1.id,
                        timestamp: operation.value1.timestamp
                    )
                )
            }
        }
    }
    
    private func user(id: User.Identifier, ownerId: User.Identifier) -> State.UserCRDT {
        if id != ownerId {
            return .sandbox(LastWriteWinsCRDT<SandboxUser>(initial: nil))
        } else {
            return .regular(LastWriteWinsCRDT<User>(initial: nil))
        }
    }
    
    func createUser(
        displayName: String,
        userId: User.Identifier?
    ) async throws {
        let operation = await Components.Schemas.Operation(
            value1: Components.Schemas.BaseOperation(
                operationId: data.infrastructure.nextId(),
                createdAt: data.infrastructure.timeMs,
                authorId: data.storage.userId
            ),
            value2: .CreateUserOperation(
                Components.Schemas.CreateUserOperation(
                    createUser: Components.Schemas.CreateUserOperation.CreateUserPayload(
                        userId: userId ?? data.infrastructure.nextId(
                            isBlacklisted: state.users.keys.contains
                        ),
                        displayName: displayName
                    )
                )
            )
        )
        try await push(operation: operation)
        await apply(operation: operation)
    }
    
    func createSpendingGroup(
        participants: [User.Identifier],
        displayName: String?
    ) async throws {
        
    }
}

struct State {
    enum UserCRDT {
        case sandbox(LastWriteWinsCRDT<SandboxUser>)
        case regular(LastWriteWinsCRDT<User>)
    }
    struct GroupParticipantIdentifier: Hashable {
        let groupId: SpendingsGroup.Identifier
        let userId: User.Identifier
    }
    
    var spendingGroupsOrder: OrderedSequenceCRDT<SpendingsGroup.Identifier>
    var spendingGroups: [SpendingsGroup.Identifier: LastWriteWinsCRDT<SpendingsGroup>]
    
    var groupsParticipantsOrder: [SpendingsGroup.Identifier: OrderedSequenceCRDT<User.Identifier>]
    var groupsParticipants: [GroupParticipantIdentifier: LastWriteWinsCRDT<SpendingsGroup.Participant>]
    
    var spendingsOrder: [SpendingsGroup.Identifier: OrderedSequenceCRDT<Spending.Identifier>]
    var spendings: [Spending.Identifier: LastWriteWinsCRDT<Spending>]
    
    var users: [User.Identifier: UserCRDT]
}
