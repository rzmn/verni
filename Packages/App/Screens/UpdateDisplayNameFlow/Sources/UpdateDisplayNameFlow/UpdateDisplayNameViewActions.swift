import Combine
import Domain

enum UpdateDisplayNameViewActionType {
    case onDisplayNameTextChanged(String)
    case onConfirmTap
}

@MainActor struct UpdateDisplayNameViewActions {
    let state: Published<UpdateDisplayNameState>.Publisher
    let handle: @MainActor (UpdateDisplayNameViewActionType) -> Void
}
