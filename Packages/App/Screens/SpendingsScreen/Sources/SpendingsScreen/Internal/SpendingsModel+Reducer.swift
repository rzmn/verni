internal import Base

extension SpendingsModel {
    static var reducer: @MainActor (SpendingsState, SpendingsAction) -> SpendingsState {
        return { state, action in
            switch action {
            case .onSearchTap:
                return state
            case .onOverallBalanceTap:
                return state
            case .onUserTap:
                return state
            }
        }
    }
}
