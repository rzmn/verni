extension UserPreviewModel {
    static var reducer: @MainActor (UserPreviewState, UserPreviewAction) -> UserPreviewState {
        return { state, action in
            switch action {
            case .onLogoutTap:
                return state
            }
        }
    }
}
