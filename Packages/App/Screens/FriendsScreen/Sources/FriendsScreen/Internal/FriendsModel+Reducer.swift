extension FriendsModel {
    static var reducer: @MainActor (FriendsState, FriendsAction) -> FriendsState {
        return { state, action in
            switch action {
            case .onLogoutTap:
                return state
            }
        }
    }
}
