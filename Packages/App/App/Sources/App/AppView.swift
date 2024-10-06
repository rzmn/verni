import SwiftUI
import DI
import AppBase
internal import SignInScreen
internal import SignUpScreen
internal import SignInOfferScreen

public struct AppView: View {
    @ObservedObject private var store: Store<AppState, AppAction>
    private let executorFactory: any ActionExecutorFactory<AppAction>

    init(
        store: Store<AppState, AppAction>,
        executorFactory: any ActionExecutorFactory<AppAction>
    ) {
        self.store = store
        self.executorFactory = executorFactory
    }

    public var body: some View {
        switch store.state {
        case .launching:
            Text("launching...")
                .onAppear {
                    store.with(executorFactory).dispatch(.launch)
                }
        case .launched(let dependencies, let state):
            LaunchedView(
                state: state,
                store: store,
                executorFactory: executorFactory,
                dependencies: dependencies
            )
        }
    }
}
