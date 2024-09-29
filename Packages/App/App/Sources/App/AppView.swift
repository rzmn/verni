import SwiftUI
import DI
import AppBase
internal import SignInScreen
internal import SignUpScreen
internal import SignInOfferScreen

public struct AppView: View {
    @ObservedObject private var store: Store<AppState, AppAction>
    private let executorFactory: any ActionExecutorFactory<AppAction>
    private let signInOfferScreen: any ScreenProvider<SignInOfferEvent, SignInOfferView>
    private let signInScreen: any ScreenProvider<SignInEvent, SignInView>
    private let signUpScreen: any ScreenProvider<SignUpEvent, SignUpView>

    init(
        store: Store<AppState, AppAction>,
        executorFactory: any ActionExecutorFactory<AppAction>,
        signInOfferScreen: any ScreenProvider<SignInOfferEvent, SignInOfferView>,
        signInScreen: any ScreenProvider<SignInEvent, SignInView>,
        signUpScreen: any ScreenProvider<SignUpEvent, SignUpView>
    ) {
        self.store = store
        self.executorFactory = executorFactory
        self.signInOfferScreen = signInOfferScreen
        self.signInScreen = signInScreen
        self.signUpScreen = signUpScreen
    }

    public var body: some View {
        switch store.state {
        case .unauthenticated(let state):
            TabView(
                selection: Binding(
                    get: {
                        state.tab
                    },
                    set: { tab in
                        store.with(executorFactory).dispatch(.selectTab(tab))
                    }
                )
            ) {
                ForEach(state.tabs) { tab in
                    switch tab {
                    case .account(let state):
                        accountTab(state: state)
                    }
                }
            }
        case .authenticated:
            Text("not implemented")
        }
    }

    private func accountTab(state: UnauthenticatedState.AccountTabState) -> some View {
        signInOfferScreen.instantiate { event in
            switch event {
            case .onSignInOfferAccepted:
                store.with(executorFactory).dispatch(.acceptedSignInOffer)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    state.signInStackVisible
                },
                set: { visible in
                    store.with(executorFactory).dispatch(.changeSignInStackVisibility(visible: visible))
                }
            )
        ) {
            signInStack(stack: state.signInStack)
        }
    }

    private func signInStack(stack: UnauthenticatedState.AccountTabState.SignInStack) -> some View {
        NavigationStack(
            path: Binding(
                get: {
                    stack.elements
                },
                set: { stack in
                    store.with(executorFactory).dispatch(.changeSignInStack(stack: stack))
                }
            )
        ) {
            signInScreen.instantiate { event in
                switch event {
                case .routeToSignUp:
                    store.with(executorFactory).dispatch(.onCreateAccount)
                case .canceled:
                    store.with(executorFactory).dispatch(.onCloseSignIn)
                case .signedIn(let container):
                    store.with(executorFactory).dispatch(.onAuthorized(container))
                }
            }
            .navigationDestination(for: UnauthenticatedState.AccountTabState.SignInStackElement.self) { selection in
                switch selection {
                case .createAccount:
                    signUpScreen.instantiate { event in
                        switch event {
                        case .created(let container):
                            store.with(executorFactory).dispatch(.onAuthorized(container))
                        }
                    }
                }
            }
        }
    }
}
