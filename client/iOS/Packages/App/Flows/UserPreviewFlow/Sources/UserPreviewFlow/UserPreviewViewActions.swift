import Domain
import Combine

enum UserPreviewViewActionType {
    case onViewAppeared
    case onSendFriendRequestTap
    case onAcceptFriendRequestTap
    case onRejectFriendRequestTap
    case onRollbackFriendRequestTap
    case onUnfriendTap
}

struct UserPreviewViewActions {
    let state: Published<UserPreviewState>.Publisher
    let handle: @MainActor (UserPreviewViewActionType) -> Void
}
