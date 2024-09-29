import Domain
import Combine

enum AccountViewActionType {
    case onUpdateAvatarTap
    case onUpdateEmailTap
    case onUpdatePasswordTap
    case onUpdateDisplayNameTap
    case onShowQrTap
    case onLogoutTap
}

@MainActor struct AccountViewActions {
    let state: Published<AccountState>.Publisher
    let handle: @MainActor (AccountViewActionType) -> Void
}
