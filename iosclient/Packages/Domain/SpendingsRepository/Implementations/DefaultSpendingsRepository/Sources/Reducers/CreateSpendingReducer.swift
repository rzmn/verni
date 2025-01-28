import Api
import Entities
import SyncEngine
internal import Convenience

func CreateSpendingReducer(
    base: Components.Schemas.BaseOperation,
    payload: Components.Schemas.CreateSpendingOperation,
    state: State
) -> State {
    modify(state) { state in
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
                            createdAt: base.createdAt,
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
                id: base.operationId,
                timestamp: base.createdAt
            )
        )
        let spendingsOrder = state.spendingsOrder[payload.createSpending.groupId, default: OrderedSequenceCRDT(initial: [])]
        state.spendingsOrder[payload.createSpending.groupId] = spendingsOrder.byInserting(
            operation: OrderedSequenceCRDT.Operation(
                kind: .insert(spendingId),
                id: base.operationId,
                timestamp: base.createdAt
            )
        )
    }
}
