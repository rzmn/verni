import Entities

public enum SpendingsGroupAction: Sendable {
    case onAppear
    case onTapBack
    case onSpendingsUpdated(SpendingsGroupState)
}
