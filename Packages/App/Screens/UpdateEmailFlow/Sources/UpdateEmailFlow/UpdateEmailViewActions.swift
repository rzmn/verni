import Combine
import Domain

enum UpdateEmailViewActionType {
    case onConfirmTap
    case onConfirmationCodeTextChanged(String)
    case onResendTap
}

@MainActor struct UpdateEmailViewActions {
    let state: Published<UpdateEmailState>.Publisher
    let handle: @MainActor (UpdateEmailViewActionType) -> Void
}
