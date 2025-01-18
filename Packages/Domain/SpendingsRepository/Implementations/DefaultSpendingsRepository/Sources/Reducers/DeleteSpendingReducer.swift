import Api
import Entities
import SyncEngine
internal import Convenience

func DeleteSpendingReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.DeleteSpendingOperation,
    state: State
) -> State {
    modify(state) {
        let spendingId = payload.deleteSpending.spendingId
        let spending = state.spendings[spendingId, default: LastWriteWinsCRDT(initial: nil)]
        $0.spendings[spendingId] = spending.byInserting(
            operation: LastWriteWinsCRDT.Operation(
                kind: .delete,
                id: base.operationId,
                timestamp: base.createdAt
            )
        )
        let spendingsOrder = state.spendingsOrder[payload.deleteSpending.groupId, default: OrderedSequenceCRDT(initial: [])]
        $0.spendingsOrder[payload.deleteSpending.groupId] = spendingsOrder.byInserting(
            operation: OrderedSequenceCRDT.Operation(
                kind: .delete(spendingId),
                id: base.operationId,
                timestamp: base.createdAt
            )
        )
    }
}
