import DI

public enum ProfileEvent: Sendable {
    case logout
    case showQrHint
    case unauthorized(reason: String)
}
