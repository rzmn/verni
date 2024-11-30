import SwiftUI
import AppBase
internal import DesignSystem

private extension Store<AppState, AppAction> {
    var localState: AnonymousState? {
        guard case .launched(let state) = state else {
            return nil
        }
        guard case .anonymous(let state) = state else {
            return nil
        }
        return state
    }
}

private extension AnonymousState.Tab {
    var id: String {
        switch self {
        case .auth:
            return "auth"
        }
    }
    
    var barTab: BottomBarTab {
        switch self {
        case .auth:
            return BottomBarTab(
                id: id,
                icon: .userCircleBorder,
                selectedIcon: .userFill
            )
        }
    }
}

struct AnonymousNavigation: View {
    @ObservedObject private var store: Store<AppState, AppAction>
    
    init(store: Store<AppState, AppAction>) {
        self.store = store
    }
    
    var body: some View {
        if let state = store.localState {
            tabs(state: state)
        } else {
            EmptyView()
        }
//            .bottomBar(
//                config: BottomBarConfig(
//                    items: store.localState.tabs
//                        .map(\.barTab)
//                        .map(BottomBarItem.tab)
//                ),
//                tab: Binding(
//                    get: {
//                        store.localState.tab.barTab
//                    }, set: { newValue in
//                        guard let tab = store.localState.tabs.first(where: { $0.id == newValue.id }) else {
//                            return assertionFailure("unexpected tab selected")
//                        }
//                        store.dispatch(.selectTabAnonymous(tab))
//                    }
//                )
//            )
    }
    
    @ViewBuilder private func tabs(state: AnonymousState) -> some View {
        switch state.tab {
        case .auth(let authState):
            authTab(state: state, authState: authState)
        }
    }
    
    @ViewBuilder private func authTab(state: AnonymousState, authState: AnonymousState.AuthState) -> some View {
        if authState.loggingIn {
            loginView(state: state)
        } else {
            authWelcomeView(state: state)
        }
    }
    
    private func loginView(state: AnonymousState) -> some View {
        state.session.logInScreen.instantiate { event in
            switch event {
            case .dismiss:
                store.dispatch(.loggingIn(false))
            case .forgotPassword:
                break
            case .logIn(let di):
                Task { @MainActor in
                    store.dispatch(
                        .onAuthorized(
                            await AuthenticatedPresentationLayerSession(
                                di: di,
                                fallback: state.session
                            )
                        )
                    )
                }
            }
        }
    }
    
    private func authWelcomeView(state: AnonymousState) -> some View {
        state.session.authWelcomeScreen.instantiate { event in
            switch event {
            case .logIn:
                store.dispatch(.loggingIn(true))
            case .signUp:
                break
            }
        }
    }
}
