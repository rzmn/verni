import Entities

public enum ProfileEvent: Sendable {
    case logout
    case showQrHint
    case openEditing
    case openActivities
    case unauthorized(reason: String)
}
