import UserPreviewScreen
internal import Convenience

extension UserPreviewModel {
    static var reducer: @MainActor (UserPreviewState, UserPreviewAction) -> UserPreviewState {
        return { state, action in
            switch action {
            case .infoUpdated(let info):
                return modify(state) {
                    $0.user = info
                }
            case .appeared, .close, .createSpendingGroup, .spendingGroupCreated:
                return state
            }
        }
    }
}
