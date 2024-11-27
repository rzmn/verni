import SwiftUI
import DI
import AppBase
internal import AuthWelcomeScreen
internal import DesignSystem

public struct AppView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject private var store: Store<AppState, AppAction>

    init(store: Store<AppState, AppAction>) {
        self.store = store
    }

    public var body: some View {
        content
            .environment(ColorPalette(scheme: colorScheme))
            .environment(PaddingsPalette.default)
    }
    
    @ViewBuilder private var content: some View {
        switch store.state {
        case .launching:
            Text("launching...")
                .onAppear {
                    store.dispatch(.launch)
                }
        case .launched(let state):
            switch state {
            case .authenticated(let state):
                switch state.tab {
                case .spendings:
                    state.session.spendingsScreen.instantiate { event in
                        switch event {
                        case .onUserTap:
                            break
                        }
                    }
                case .profile:
                    state.session.profileScreen.instantiate { event in
                        switch event {
                        case .logout:
                            store.dispatch(.logout(state.session.fallback))
                        }
                    }
                }
            case .anonymous(let state):
                switch state.tab {
                case .auth(let auth):
                    if auth.loggingIn {
                        state.session.logInScreen.instantiate { event in
                            switch event {
                            case .dismiss:
                                store.dispatch(.loggingIn(false))
                            case .forgotPassword:
                                break
                            case .logIn(let session):
                                Task { @MainActor in
                                    store.dispatch(
                                        .onAuthorized(
                                            await AuthenticatedPresentationLayerSession(
                                                di: session,
                                                fallback: state.session
                                            )
                                        )
                                    )
                                }
                            }
                        }
                    } else {
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
            }
        }
    }
}
