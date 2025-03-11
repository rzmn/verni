import Entities

public enum UserPreviewEvent: Sendable {
    case closed
    case spendingGroupCreated(SpendingGroup.Identifier)
}
