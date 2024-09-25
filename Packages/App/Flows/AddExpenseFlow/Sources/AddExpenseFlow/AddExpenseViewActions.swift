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

@MainActor final class Store<State: Sendable & Equatable, Action: Sendable>: ObservableObject {
    @Published private(set) var state: State
    let handle: @MainActor (Action) -> Void

    init(
        current: State,
        publisher: Published<State>.Publisher? = nil,
        handle: @MainActor @escaping (Action) -> Void
    ) {
        self.state = current
        self.handle = handle
        publisher?.assign(to: &$state)
    }
}
