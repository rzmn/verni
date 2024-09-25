import Domain
import Combine

enum AddExpenseViewActionType: Sendable {
    case onCancelTap
    case onDoneTap
    case onPickCounterpartyTap
    case onSplitRuleTap(equally: Bool)
    case onOwnershipSelected(rule: AddExpenseState.ExpenseOwnership)
    case onDescriptionChanged(String)
    case onExpenseAmountChanged(String)
}

@MainActor final class AddExpenseViewModel: ObservableObject {
    var state: AddExpenseState
    let handle: @MainActor (AddExpenseViewActionType) -> Void

    init(state: AddExpenseState, handle: @MainActor @escaping (AddExpenseViewActionType) -> Void) {
        self.state = state
        self.handle = handle
    }
}
