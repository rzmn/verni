import SwiftUI
import AppBase

struct LaunchedView: View {
    @ObservedObject private var store: Store<AppState, AppAction>
    private let executorFactory: any ActionExecutorFactory<AppAction>
    private let dependencies: AppDependencies
    private let state: LaunchedState

    init(
        state: LaunchedState,
        store: Store<AppState, AppAction>,
        executorFactory: any ActionExecutorFactory<AppAction>,
        dependencies: AppDependencies
    ) {
        self.store = store
        self.executorFactory = executorFactory
        self.dependencies = dependencies
        self.state = state
    }

    public var body: some View {
        switch state {
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
