public enum SignUpEvent<Session: Sendable>: Sendable {
    case dismiss
    case forgotPassword
    case signUp(Session)
}
