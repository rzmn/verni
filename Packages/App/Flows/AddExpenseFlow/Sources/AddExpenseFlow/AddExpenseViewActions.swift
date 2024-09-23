import Domain
import Combine

enum AddExpenseViewActionType {
    case onCancelTap
    case onDoneTap
    case onPickCounterpartyTap
    case onSplitRuleTap(equally: Bool)
    case onOwnershipTap(iOwe: Bool)
    case onDescriptionChanged(String)
    case onExpenseAmountChanged(String)
}

@MainActor struct AddExpenseViewActions {
    let state: Published<AddExpenseState>.Publisher
    let handle: @MainActor (AddExpenseViewActionType) -> Void
}
