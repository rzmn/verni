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
    
    @State private var authWelcomeDestinationOffset: CGFloat?
    @State private var loginSourceOffset: CGFloat?
    
    @State private var toLoginScreenTransitionProgress: CGFloat = 0
    
    @Binding private var fromSplashTransitionProgress: CGFloat
    
    init(store: Store<AppState, AppAction>, fromSplashTransitionProgress: Binding<CGFloat>) {
        self.store = store
        _fromSplashTransitionProgress = fromSplashTransitionProgress
    }
    
    var body: some View {
        if let state = store.localState {
            tabs(state: state)
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder private func tabs(state: AnonymousState) -> some View {
        switch state.tab {
        case .auth(let authState):
            authTab(state: state, authState: authState)
        }
    }
    
    @ViewBuilder private func authTab(state: AnonymousState, authState: AnonymousState.AuthState) -> some View {
        ZStack {
            authWelcomeView(state: state)
            loginView(state: state)
                .opacity(toLoginScreenTransitionProgress)
        }
    }
    
    private func loginView(state: AnonymousState) -> some View {
        state.session.logInScreen.instantiate { event in
            switch event {
            case .dismiss:
                withAnimation(.default) {
                    toLoginScreenTransitionProgress = 0
                }
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
        }(BottomSheetTransition(progress: $toLoginScreenTransitionProgress, sourceOffset: $loginSourceOffset, destinationOffset: $authWelcomeDestinationOffset))
    }
    
    private func authWelcomeView(state: AnonymousState) -> some View {
        state.session.authWelcomeScreen.instantiate { event in
            switch event {
            case .logIn:
                withAnimation(.default) {
                    toLoginScreenTransitionProgress = 1.0
                }
            case .signUp:
                break
            }
        }(
            TwoSideTransition(
                from: BottomSheetTransition(
                    progress: $fromSplashTransitionProgress,
                    sourceOffset: .constant(0),
                    destinationOffset: $authWelcomeDestinationOffset
                ),
                to: BottomSheetTransition(
                    progress: $toLoginScreenTransitionProgress,
                    sourceOffset: $authWelcomeDestinationOffset,
                    destinationOffset: $loginSourceOffset
                )
            )
        )
    }
}
