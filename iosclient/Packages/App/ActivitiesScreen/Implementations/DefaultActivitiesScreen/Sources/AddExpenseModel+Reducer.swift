import ActivitiesScreen
internal import Convenience

extension ActivitiesModel {
    static var reducer: @MainActor (ActivitiesState, ActivitiesAction) -> ActivitiesState {
        return { state, action in
            switch action {
            case .appeared, .cancel:
                return state
            case .onDataUpdated(let operations):
                return modify(state) {
                    $0.operations = operations
                }
            }
        }
    }
}
