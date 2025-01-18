import Api
import Entities
import SyncEngine
internal import Convenience

func DeleteSpendingGroupReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.DeleteSpendingGroupOperation,
    state: State
) -> State {
    modify(state) {
        let groupId = payload.deleteSpendingGroup.groupId
        let group = state.spendingGroups[groupId, default: LastWriteWinsCRDT(initial: nil)]
        $0.spendingGroups[groupId] = group.byInserting(
            operation: LastWriteWinsCRDT.Operation(
                kind: .delete,
                id: base.operationId,
                timestamp: base.createdAt
            )
        )
        $0.spendingGroupsOrder = $0.spendingGroupsOrder.byInserting(
            operation: OrderedSequenceCRDT.Operation(
                kind: .delete(groupId),
                id: base.operationId,
                timestamp: base.createdAt
            )
        )
    }
}
