import Domain
import Combine

enum UpdatePasswordViewActionType {
    case onOldPasswordTextChanged(String)
    case onNewPasswordTextChanged(String)
    case onRepeatNewPasswordTextChanged(String)
    case onUpdateTap
}

struct UpdatePasswordViewActions {
    let state: Published<UpdatePasswordState>.Publisher
    let handle: @MainActor (UpdatePasswordViewActionType) -> Void
}
