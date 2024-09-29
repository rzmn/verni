import Domain
import Combine

enum PickCounterpartyViewActionType {
    case onCancelTap
    case onPickounterpartyTap(User)
    case onViewAppeared
}

@MainActor struct PickCounterpartyViewActions {
    let state: Published<PickCounterpartyState>.Publisher
    let handle: @MainActor (PickCounterpartyViewActionType) -> Void
}
