import SpendingsScreen
internal import Convenience

extension SpendingsModel {
    static var reducer: @MainActor (SpendingsState, SpendingsAction) -> SpendingsState {
        return { state, action in
            switch action {
            case .onSearchTap:
                return state
            case .onAppear:
                return state
            case .onOverallBalanceTap:
                return state
            case .onUserTap:
                return state
            case .balanceUpdated(let balance):
                return modify(state) {
                    $0.previews = balance
                }
            }
        }
    }
}
