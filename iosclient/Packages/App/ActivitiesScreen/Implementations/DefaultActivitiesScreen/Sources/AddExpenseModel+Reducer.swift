import ActivitiesScreen
import Foundation
internal import Convenience

extension ActivitiesModel {
    static var reducer: @MainActor (ActivitiesState, ActivitiesAction) -> ActivitiesState {
        return { state, action in
            switch action {
            case .appeared:
                return state
            case .cancel:
                return modify(state) {
                    $0.sessionId = UUID()
                }
            case .onDataUpdated(let operations):
                return modify(state) {
                    $0.operations = operations
                }
            }
        }
    }
}
