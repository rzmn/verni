import Foundation
import Combine

@MainActor class AuthenticatedViewModel {
    @Published var state: AuthenticatedState

    @Published var tabs: [AuthenticatedState.Tab]
    @Published var activeTab: AuthenticatedState.Tab

    init() {
        let initial = AuthenticatedState(
            tabs: [
                .friends,
                .account
            ],
            activeTab: .friends
        )
        state = initial
        activeTab = initial.activeTab
        tabs = initial.tabs
        setupStateBuilder()
    }

    private func setupStateBuilder() {
        Publishers.CombineLatest($tabs, $activeTab)
            .map { tabs, activeTab in
                AuthenticatedState(
                    tabs: tabs,
                    activeTab: activeTab
                )
            }
            .receive(on: RunLoop.main)
            .assign(to: &$state)
    }
}
