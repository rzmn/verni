import SwiftUI
import AppBase

struct SignInNavigationView: View {
    typealias State = UnauthenticatedState.AccountTabState.SignInStack
    typealias Element = UnauthenticatedState.AccountTabState.SignInStackElement

    @ObservedObject private var store: Store<AppState, AppAction>
    private let executorFactory: any ActionExecutorFactory<AppAction>
    private let dependencies: AppDependencies

    init(
        store: Store<AppState, AppAction>,
        executorFactory: any ActionExecutorFactory<AppAction>,
        dependencies: AppDependencies
    ) {
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
            .navigationDestination(for: Element.self) { selection in
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
        Binding {
            guard case .launched(_, let state) = store.state, case .unauthenticated(let state) = state else {
                return []
            }
            return state.tabs.compactMap { tab -> [Element]? in
                guard case .account(let state) = tab else {
                    return nil
                }
                return state.signInStack.elements
            }.first ?? []
        } set: { stack in
            store.with(executorFactory).dispatch(.changeSignInStack(stack: stack))
        }
    }
}
