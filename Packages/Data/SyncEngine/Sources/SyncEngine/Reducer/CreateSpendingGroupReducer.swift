import Api
import Domain
import Base

private extension String {
    func operationId(insertingAt index: Int) -> String {
        self + "_insert_\(String(format: "%03d", index))"
    }
    
    func operationId(creating userId: String) -> String {
        self + "_create_\(userId)"
    }
}

func CreateSpendingGroupReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.CreateSpendingGroupOperation,
    state: State
) -> State {
    modify(state) {
        let groupId = payload.createSpendingGroup.groupId
        let group = state.spendingGroups[groupId, default: LastWriteWinsCRDT(initial: nil)]
        $0.spendingGroups[groupId] = group.byInserting(
            operation: LastWriteWinsCRDT.Operation(
                kind: .create(
                    SpendingGroup(
                        id: groupId,
                        name: payload.createSpendingGroup.displayName,
                        createdAt: base.createdAt
                    )
                ),
                id: base.operationId,
                timestamp: base.createdAt
            )
        )
        $0.spendingGroupsOrder = $0.spendingGroupsOrder.byInserting(
            operation: OrderedSequenceCRDT.Operation(
                kind: .insert(groupId),
                id: base.operationId,
                timestamp: base.createdAt
            )
        )
        $0.groupParticipantsOrder[groupId] = $0.groupParticipantsOrder[groupId, default: OrderedSequenceCRDT(initial: [])]
            .byInserting(
                operations: payload.createSpendingGroup.participants.enumerated().map { (index, id) in
                        .init(
                            kind: .insert(id),
                            id: base.operationId.operationId(insertingAt: index),
                            timestamp: base.createdAt
                        )
                }
            )
        for participantId in payload.createSpendingGroup.participants {
            let id = State.GroupParticipantIdentifier(
                groupId: groupId,
                userId: participantId
            )
            let status: SpendingGroup.Participant.Status
            if let user = state.users[participantId] {
                switch user {
                case .regular:
                    status = .invited
                case .sandbox:
                    status = .member
                }
            } else {
                assertionFailure()
                status = .member
            }
            $0.groupParticipants[id] = $0.groupParticipants[id, default: LastWriteWinsCRDT(initial: nil)]
                .byInserting(
                    operation: LastWriteWinsCRDT.Operation(
                        kind: .create(
                            SpendingGroup.Participant(
                                userId: participantId,
                                status: status
                            )
                        ),
                        id: base.operationId.operationId(creating: participantId),
                        timestamp: base.createdAt
                    )
                )
        }
    }
}
