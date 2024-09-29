extension AppModel {
    static var initialState: AppState {
        let accountTab = UnauthenticatedState.TabState.account(
            UnauthenticatedState.AccountTabState(
                signInStack: UnauthenticatedState.AccountTabState.SignInStack(
                    elements: []
                ),
                signInStackVisible: false
            )
        )
        return .unauthenticated(
            UnauthenticatedState(
                tabs: [accountTab],
                tab: accountTab
            )
        )
    }
}
