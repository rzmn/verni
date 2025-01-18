import AsyncExtensions
import SpendingsRepository
import Entities
import InfrastructureLayer
import Api
import Logging
import PersistentStorage
import SyncEngine
internal import Convenience

actor DefaultSpendingsRepository: Sendable {
    let logger: Logger
    private let infrastructure: InfrastructureLayer
    private let reducer: Reducer
    private var state: State
    private let sync: Engine
    private let userId: User.Identifier
    
    private let updatesSubject: AsyncSubject<[SpendingsUpdate]>
    private var remoteUpdatesSubscription: BlockAsyncSubscription<[Components.Schemas.Operation]>?
    
    init(
        reducer: @escaping Reducer = DefaultReducer(
            createSpendingGroupReducer: CreateSpendingGroupReducer,
            deleteSpendingGroupReducer: DeleteSpendingGroupReducer,
            createSpendingReducer: CreateSpendingReducer,
            deleteSpendingReducer: DeleteSpendingReducer
        ),
        userId: User.Identifier,
        sync: Engine,
        infrastructure: InfrastructureLayer,
        logger: Logger
    ) async {
        self.logger = logger
        self.state = State(
            spendingGroupsOrder: OrderedSequenceCRDT(initial: []),
            spendingGroups: [:],
            groupParticipantsOrder: [:],
            groupParticipants: [:],
            spendingsOrder: [:],
            spendings: [:]
        )
        self.reducer = reducer
        self.infrastructure = infrastructure
        self.sync = sync
        self.userId = userId
        updatesSubject = AsyncSubject(
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
        let updates = modify([SpendingsUpdate]()) { updates in
            if oldState.spendingGroupsOrder.elements != state.spendingGroupsOrder.elements {
                updates.append(.spendingGroupsUpdated(state.spendingGroupsOrder.elements))
            }
            updates.append(
                contentsOf: state.spendingGroupsOrder.elements.compactMap { groupId in
                    let getParticipant: (State, User.Identifier) -> SpendingGroup.Participant? = {
                        $0.groupParticipants[State.GroupParticipantIdentifier(groupId: groupId, userId: $1)]?.value
                    }
                    guard
                        let oldGroup = oldState.spendingGroups[groupId]?.value,
                        let oldGroupParticipantIds = oldState.groupParticipantsOrder[groupId],
                        let newGroup = state.spendingGroups[groupId]?.value,
                        let newGroupParticipantIds = state.groupParticipantsOrder[groupId]
                    else {
                        return nil
                    }
                    let oldGroupParticipants = oldGroupParticipantIds.elements
                        .compactMap { getParticipant(oldState, $0) }
                    let newGroupParticipants = newGroupParticipantIds.elements
                        .compactMap { getParticipant(oldState, $0) }
                    guard oldGroup != newGroup || oldGroupParticipants != newGroupParticipants else {
                        return nil
                    }
                    return .spendingGroupUpdated(newGroup, participants: newGroupParticipants)
                }
            )
            updates.append(
                contentsOf: state.spendingGroupsOrder.elements.flatMap { groupId -> [SpendingsUpdate] in
                    guard
                        let oldSpendings = oldState.spendingsOrder[groupId],
                        let newSpendings = state.spendingsOrder[groupId]
                    else {
                        return []
                    }
                    let updates: [SpendingsUpdate]
                    if oldSpendings.elements != newSpendings.elements {
                        updates = [.spendingsListUpdated(groupId, newSpendings.elements)]
                    } else {
                        updates = []
                    }
                    return updates + newSpendings.elements.compactMap { spendingId in
                        guard
                            let oldSpending = oldState.spendings[spendingId]?.value,
                            let newSpending = state.spendings[spendingId]?.value
                        else {
                            return nil
                        }
                        guard oldSpending != newSpending else {
                            return nil
                        }
                        return .spendingUpdated(spendingId, newSpending)
                    }
                }
            )
        }
        infrastructure.taskFactory.detached { [weak updatesSubject] in
            await updatesSubject?.yield(updates)
        }
    }
    
    private var isSpendingIdReserved: (Spending.Identifier) -> Bool {
        state.spendings.keys.contains
    }
    
    private var isSpendingGroupIdReserved: (Spending.Identifier) -> Bool {
        state.spendingGroups.keys.contains
    }
    
    private var isOperationIdReserved: (SpendingGroup.Identifier) -> Bool {
        get async {
            Set(await sync.operations.map(\.value1.operationId)).contains
        }
    }
}

extension DefaultSpendingsRepository: SpendingsRepository {
    nonisolated var updates: any AsyncBroadcast<[SpendingsUpdate]> {
        updatesSubject
    }
    
    subscript(spending: Spending.Identifier) -> Spending? {
        get async {
            state.spendings[spending]?.value
        }
    }
    
    subscript(group groupId: SpendingGroup.Identifier) -> (group: SpendingGroup, participants: [SpendingGroup.Participant])? {
        get async {
            guard
                let group = state.spendingGroups[groupId]?.value,
                let participantsIds = state.groupParticipantsOrder[groupId]
            else {
                return nil
            }
            let participants = participantsIds.elements
                .map { userId in
                    State.GroupParticipantIdentifier(groupId: groupId, userId: userId)
                }
                .compactMap { id in
                    state.groupParticipants[id]?.value
                }
            return (group, participants)
        }
    }
    
    subscript(spendingsIn group: SpendingGroup.Identifier) -> [Spending]? {
        get async {
            state.spendingsOrder[group].map { sequence in
                sequence.elements.compactMap { spendingId in
                    state.spendings[spendingId]?.value
                }
            }
        }
    }
    
    func createGroup(
        participants: [User.Identifier],
        displayName: String?
    ) async throws(CreateSpendingGroupError) -> SpendingGroup.Identifier {
        let groupId = infrastructure.nextId(
            isBlacklisted: isSpendingGroupIdReserved
        )
        let operation = await Components.Schemas.Operation(
            value1: Components.Schemas.BaseOperation(
                operationId: infrastructure.nextId(
                    isBlacklisted: isOperationIdReserved
                ),
                createdAt: infrastructure.timeMs,
                authorId: userId
            ),
            value2: .CreateSpendingGroupOperation(
                .init(
                    createSpendingGroup: .init(
                        groupId: groupId,
                        participants: participants,
                        displayName: displayName
                    )
                )
            )
        )
        do {
            try await sync.push(operation: operation)
        } catch {
            throw .internal(error)
        }
        received(operation: operation)
        return groupId
    }
    
    func deleteGroup(
        id: SpendingGroup.Identifier
    ) async throws(DeleteSpendingGroupError) {
        guard state.spendingGroups[id]?.value != nil else {
            throw .groupNotFound
        }
        guard state.groupParticipants[State.GroupParticipantIdentifier(groupId: id, userId: userId)]?.value?.status == .member else {
            throw .notAllowed
        }
        let operation = await Components.Schemas.Operation(
            value1: Components.Schemas.BaseOperation(
                operationId: infrastructure.nextId(
                    isBlacklisted: isOperationIdReserved
                ),
                createdAt: infrastructure.timeMs,
                authorId: userId
            ),
            value2: .DeleteSpendingGroupOperation(
                .init(
                    deleteSpendingGroup: .init(
                        groupId: id
                    )
                )
            )
        )
        do {
            try await sync.push(operation: operation)
        } catch {
            throw .internal(error)
        }
        return received(operation: operation)
    }
    
    func createSpending(
        in groupId: SpendingGroup.Identifier,
        displayName: String,
        currency: Currency,
        amount: Amount,
        shares: [Spending.Share]
    ) async throws(CreateSpendingError) -> Spending.Identifier {
        guard state.spendingGroups[groupId]?.value != nil else {
            throw .groupNotFound
        }
        guard state.groupParticipants[State.GroupParticipantIdentifier(groupId: groupId, userId: userId)]?.value?.status == .member else {
            throw .notAllowed
        }
        for share in shares {
            guard state.groupParticipants[State.GroupParticipantIdentifier(
                groupId: groupId,
                userId: share.userId
            )] != nil else {
                throw .participantNotFoundInGroup
            }
        }
        let spendingId = infrastructure.nextId(
            isBlacklisted: isSpendingIdReserved
        )
        let operation = await Components.Schemas.Operation(
            value1: Components.Schemas.BaseOperation(
                operationId: infrastructure.nextId(
                    isBlacklisted: isOperationIdReserved
                ),
                createdAt: infrastructure.timeMs,
                authorId: userId
            ),
            value2: .CreateSpendingOperation(
                .init(
                    createSpending: .init(
                        spendingId: spendingId,
                        groupId: groupId,
                        name: displayName,
                        currency: currency.stringValue,
                        amount: Int64(amount: amount),
                        shares: shares.map{ share in
                            Components.Schemas.SpendingShare(
                                userId: share.userId,
                                amount: Int64(amount: share.amount)
                            )
                        }
                    )
                )
            )
        )
        do {
            try await sync.push(operation: operation)
        } catch {
            throw .internal(error)
        }
        received(operation: operation)
        return spendingId
    }
    
    func deleteSpending(
        groupId: SpendingGroup.Identifier,
        spendingId: SpendingGroup.Identifier
    ) async throws(DeleteSpendingError) {
        guard state.spendingGroups[groupId]?.value != nil else {
            throw .groupNotFound
        }
        guard state.spendings[spendingId]?.value != nil else {
            throw .spendingNotFound
        }
        guard let spendings = state.spendingsOrder[groupId]?.elements, spendings.contains(spendingId) else {
            throw .notAllowed
        }
        guard state.groupParticipants[State.GroupParticipantIdentifier(groupId: groupId, userId: userId)]?.value?.status == .member else {
            throw .notAllowed
        }
        let operation = await Components.Schemas.Operation(
            value1: Components.Schemas.BaseOperation(
                operationId: infrastructure.nextId(
                    isBlacklisted: isOperationIdReserved
                ),
                createdAt: infrastructure.timeMs,
                authorId: userId
            ),
            value2: .DeleteSpendingOperation(
                .init(
                    deleteSpending: .init(
                        spendingId: spendingId,
                        groupId: groupId
                    )
                )
            )
        )
        do {
            try await sync.push(operation: operation)
        } catch {
            throw .internal(error)
        }
        return received(operation: operation)
    }
}
