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
            case .submit, .cancel, .expenseAdded:
                return state
            }
        }
    }
}
