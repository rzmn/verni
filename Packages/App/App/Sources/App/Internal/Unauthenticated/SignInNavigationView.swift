import SwiftUI
import AppBase

struct SignInNavigationView: View {
    typealias State = UnauthenticatedState.AccountTabState.SignInStack
    typealias Element = UnauthenticatedState.AccountTabState.SignInStackElement

    private let state: State
    @ObservedObject private var store: Store<AppState, AppAction>
    private let executorFactory: any ActionExecutorFactory<AppAction>
    private let dependencies: AppDependencies

    init(
        state: State,
        store: Store<AppState, AppAction>,
        executorFactory: any ActionExecutorFactory<AppAction>,
        dependencies: AppDependencies
    ) {
        self.state = state
        self.store = store
        self.executorFactory = executorFactory
        self.dependencies = dependencies
    }

    var body: some View {
        NavigationStack(path: navigationPath) {
            dependencies.signInScreen.instantiate { event in
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
                    dependencies.signUpScreen.instantiate { event in
                        switch event {
                        case .created(let container):
                            store.with(executorFactory).dispatch(.onAuthorized(container))
                        }
                    }
                }
            }
        }
    }

    private var navigationPath: Binding<[Element]> {
        Binding(
            get: {
                state.elements
            },
            set: { stack in
                store.with(executorFactory).dispatch(.changeSignInStack(stack: stack))
            }
        )
    }
}
