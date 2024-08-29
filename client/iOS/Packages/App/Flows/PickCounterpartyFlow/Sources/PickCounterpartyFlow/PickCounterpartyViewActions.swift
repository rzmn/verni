import Domain
import Combine

enum PickCounterpartyViewActionType {
    case onCancelTap
    case onPickounterpartyTap(User)
    case onViewAppeared
}

struct PickCounterpartyViewActions {
    let state: Published<PickCounterpartyState>.Publisher
    let handle: @MainActor (PickCounterpartyViewActionType) -> Void
}
