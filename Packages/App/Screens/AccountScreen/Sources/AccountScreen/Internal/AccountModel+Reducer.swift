extension AccountModel {
    static var reducer: @MainActor (AccountState, AccountAction) -> AccountState {
        return { state, action in
            switch action {
            case .onLogoutTap:
                return state
            }
        }
    }
}
