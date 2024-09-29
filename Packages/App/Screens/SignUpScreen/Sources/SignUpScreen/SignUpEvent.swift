import DI

public enum SignUpEvent: Sendable {
    case created(ActiveSessionDIContainer)
}
