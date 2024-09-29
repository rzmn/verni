import DI

extension AppModel {
    static var reducer: @MainActor @Sendable (AppState, AppAction) -> AppState {
        return { state, action in
            let unexpectedState: () -> AppState = {
                assertionFailure("unexpected path: got action \(action) in state \(state)")
                return state
            }
            switch action {
            case .acceptedSignInOffer:
                return state
            case .onCreateAccount:
                return state
            case .onCloseSignIn:
                return state
            case .onAuthorized:
                return state
            case .changeSignInStack(let elements):
                guard case .unauthenticated(let state) = state else {
                    return unexpectedState()
                }
                guard let newAccountTab: UnauthenticatedState.TabState = state.tabs.compactMap({ tab in
                    guard case .account(let state) = tab else {
                        return nil
                    }
                    return .account(
                        UnauthenticatedState.AccountTabState(
                            signInStack: UnauthenticatedState.AccountTabState.SignInStack(
                                elements: elements
                            ),
                            signInStackVisible: state.signInStackVisible
                        )
                    )
                }).first else {
                    return unexpectedState()
                }
                let newTabs = state.tabs.map { tab in
                    guard case .account = tab else {
                        return tab
                    }
                    return newAccountTab
                }
                return .unauthenticated(
                    UnauthenticatedState(
                        tabs: newTabs,
                        tab: newAccountTab
                    )
                )
            case .changeSignInStackVisibility(let visible):
                guard case .unauthenticated(let state) = state else {
                    return unexpectedState()
                }
                guard let newAccountTab: UnauthenticatedState.TabState = state.tabs.compactMap({ tab in
                    guard case .account(let state) = tab else {
                        return nil
                    }
                    return .account(
                        UnauthenticatedState.AccountTabState(
                            signInStack: state.signInStack,
                            signInStackVisible: visible
                        )
                    )
                }).first else {
                    return unexpectedState()
                }
                let newTabs = state.tabs.map { tab in
                    guard case .account = tab else {
                        return tab
                    }
                    return newAccountTab
                }
                return .unauthenticated(
                    UnauthenticatedState(
                        tabs: newTabs,
                        tab: newAccountTab
                    )
                )
            case .selectTab(let tabToSelect):
                guard case .unauthenticated(let state) = state else {
                    return unexpectedState()
                }
                let newTabs = state.tabs.map { tab in
                    if tabToSelect.id == tab.id {
                        return tabToSelect
                    } else {
                        return tab
                    }
                }
                return .unauthenticated(
                    UnauthenticatedState(
                        tabs: newTabs,
                        tab: tabToSelect
                    )
                )
            }
        }
    }
}
