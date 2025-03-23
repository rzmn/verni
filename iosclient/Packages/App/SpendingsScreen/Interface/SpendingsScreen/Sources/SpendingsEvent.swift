import Entities

public enum SpendingsEvent: Sendable {
    case onGroupTap(SpendingGroup.Identifier)
}
