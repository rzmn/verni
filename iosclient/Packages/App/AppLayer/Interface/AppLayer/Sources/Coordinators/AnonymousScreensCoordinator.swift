import SwiftUI
import AppBase
import AuthWelcomeScreen
import DesignSystem

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

struct AnonymousScreensCoordinator: View {
    @ObservedObject private var store: Store<AppState, AppAction>

    @State private var authWelcomeDestinationOffset: CGFloat?
    @State private var loginSourceOffset: CGFloat?
    @State private var signUpSourceOffset: CGFloat?

    @State private var toSignUpScreenTransitionProgress: CGFloat = 0
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
            signUpView(state: state)
                .opacity(toSignUpScreenTransitionProgress)
        }
    }

    private func loginView(state: AnonymousState) -> some View {
        state.session.logIn.instantiate { event in
            switch event {
            case .dismiss:
                withAnimation(.default) {
                    toLoginScreenTransitionProgress = 0
                }
            case .forgotPassword:
                break
            case .logIn(let session):
                store.dispatch(.logIn(session, state))
            }
        }(loginTransitions)
    }
    
    private func signUpView(state: AnonymousState) -> some View {
        state.session.signUp.instantiate { event in
            switch event {
            case .dismiss:
                withAnimation(.default) {
                    toSignUpScreenTransitionProgress = 0
                }
            case .forgotPassword:
                break
            case .signUp(let session):
                store.dispatch(.logIn(session, state))
            }
        }(signUpTransitions)
    }

    private var loginTransitions: ModalTransition {
        ModalTransition(
            progress: $toLoginScreenTransitionProgress,
            sourceOffset: $loginSourceOffset,
            destinationOffset: $authWelcomeDestinationOffset
        )
    }
    
    private var signUpTransitions: ModalTransition {
        ModalTransition(
            progress: $toSignUpScreenTransitionProgress,
            sourceOffset: $signUpSourceOffset,
            destinationOffset: $authWelcomeDestinationOffset
        )
    }

    private func authWelcomeView(state: AnonymousState) -> some View {
        state.session.auth.instantiate { event in
            switch event {
            case .logIn:
                withAnimation(.default) {
                    toLoginScreenTransitionProgress = 1.0
                }
            case .signUp:
                withAnimation(.default) {
                    toSignUpScreenTransitionProgress = 1.0
                }
            }
        }(authWelcomeTransitions)
    }

    private var authWelcomeTransitions: AuthWelcomeTransitions {
        AuthWelcomeTransitions(
            appear: ModalTransition(
                progress: $fromSplashTransitionProgress,
                sourceOffset: .constant(0),
                destinationOffset: $authWelcomeDestinationOffset
            ),
            dismiss: ModalTransition(
                progress: Binding(get: {
                    max(toLoginScreenTransitionProgress, toSignUpScreenTransitionProgress)
                }, set: { newValue in
                    toLoginScreenTransitionProgress = newValue
                    toSignUpScreenTransitionProgress = newValue
                }),
                sourceOffset: $authWelcomeDestinationOffset,
                destinationOffset: Binding(get: {
                    loginSourceOffset ?? signUpSourceOffset
                }, set: { newValue in
                    loginSourceOffset = newValue
                    signUpSourceOffset = newValue
                })
            )
        )
    }
}
