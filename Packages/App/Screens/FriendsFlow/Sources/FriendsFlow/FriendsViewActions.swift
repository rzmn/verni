import Domain
import Combine

enum FriendsViewActionType {
    case onAddViaQrTap
    case onUserSelected(User)
    case onViewAppeared
    case onPulledToRefresh
}

@MainActor struct FriendsViewActions {
    let state: Published<FriendsState>.Publisher
    let handle: @MainActor (FriendsViewActionType) -> Void
}
