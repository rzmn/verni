import Domain
import Combine

enum AddExpenseUserAction: Sendable {
    case onCancelTap
    case onDoneTap
    case onPickCounterpartyTap
    case onSplitRuleTap(equally: Bool)
    case onOwnershipSelected(rule: AddExpenseState.ExpenseOwnership)
    case onDescriptionChanged(String)
    case onExpenseAmountChanged(String)
}
