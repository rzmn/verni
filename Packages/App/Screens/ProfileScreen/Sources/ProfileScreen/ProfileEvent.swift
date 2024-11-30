import DI

public enum ProfileEvent: Sendable {
    case logout
    case unauthorized(reason: String)
}
