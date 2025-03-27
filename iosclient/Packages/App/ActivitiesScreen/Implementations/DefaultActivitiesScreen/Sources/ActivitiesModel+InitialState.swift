import ActivitiesScreen
import Entities
import Foundation

extension ActivitiesModel {
    static var initialState: ActivitiesState {
        ActivitiesState(
            operations: [],
            sessionId: UUID()
        )
    }
}
