import SwiftUI
import AppBase

struct AccountTabView: View {
    typealias State = UnauthenticatedState.AccountTabState
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
        dependencies.signInOfferScreen.instantiate { event in
            switch event {
            case .onSignInOfferAccepted:
                store.with(executorFactory).dispatch(.acceptedSignInOffer)
            }
        }
        .fullScreenCover(isPresented: isSignInPresented) {
            SignInNavigationView(
                store: store,
                executorFactory: executorFactory,
                dependencies: dependencies
            )
        }
    }

    private var isSignInPresented: Binding<Bool> {
        Binding {
            state.signInStackVisible
        } set: { visible in
            store.with(executorFactory).dispatch(.changeSignInStackVisibility(visible: visible))
        }
    }
}
