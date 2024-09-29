import SwiftUI
import DI
import AppBase
internal import SignInScreen
internal import SignUpScreen
internal import SignInOfferScreen

public struct AppView: View {
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

    public var body: some View {
        switch store.state {
        case .unauthenticated(let state):
            UnauthenticatedTabsView(
                state: state,
                store: store,
                executorFactory: executorFactory,
                dependencies: dependencies
            )
        case .authenticated:
            Text("not implemented")
        }
    }
}
