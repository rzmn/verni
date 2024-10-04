extension AddExpenseModel {
    static var reducer: @MainActor (AddExpenseState, AddExpenseAction) -> AddExpenseState {
        return { state, action in
            switch action {
            case .onLogoutTap:
                return state
            }
        }
    }
}
