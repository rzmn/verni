import SpendingsGroupScreen
internal import Convenience

extension SpendingsGroupModel {
    static var reducer: @MainActor (SpendingsGroupState, SpendingsGroupAction) -> SpendingsGroupState {
        return { state, action in
            switch action {
            case .onAppear:
                return state
            case .onTapBack:
                return state
            case .onSpendingsUpdated(let state):
                return state
            }
        }
    }
}
