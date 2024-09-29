import SwiftUI
import AppBase

struct UnauthenticatedTabsView: View {
    typealias State = UnauthenticatedState

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
        TabView(selection: selectedTab) {
            ForEach(state.tabs) { tab in
                switch tab {
                case .account(let state):
                    AccountTabView(
                        state: state,
                        store: store,
                        executorFactory: executorFactory,
                        dependencies: dependencies
                    ).tabItem {
                        Label("account_nav_title".localized, systemImage: "person.circle")
                    }
                }
            }
        }
    }

    private var selectedTab: Binding<UnauthenticatedState.TabState> {
        Binding(
            get: {
                state.tab
            },
            set: { tab in
                store.with(executorFactory).dispatch(.selectTab(tab))
            }
        )
    }
}
