import AddExpenseScreen
internal import Convenience

extension AddExpenseModel {
    static var reducer: @MainActor (AddExpenseState, AddExpenseAction) -> AddExpenseState {
        return { state, action in
            switch action {
            case .selectSplitRule(let rule):
                return modify(state) {
                    $0.splitRule = rule
                }
            case .amountChanged(let amount):
                return modify(state) {
                    $0.amount = amount
                }
            case .titleChanged(let title):
                return modify(state) {
                    $0.title = title
                }
            case .paidByHostToggled:
                return modify(state) {
                    $0.paidByHost = !$0.paidByHost
                }
            case .errorOccured(let reason):
                return modify(state) {
                    $0.title = reason
                }
            case .availableCounterpartiesUpdated(let counterparties):
                return modify(state) { state in
                    state.counterparty = counterparties.first {
                        $0.id == state.counterparty?.id
                    }
                    state.availableCounterparties = counterparties
                }
            case .submit, .cancel, .expenseAdded, .appeared:
                return state
            case .selectCounterparty(let id):
                return modify(state) { state in
                    if let id {
                        state.counterparty = state.availableCounterparties.first {
                            $0.id == id
                        }
                    } else {
                        state.counterparty = nil
                    }
                }
            }
        }
    }
}
