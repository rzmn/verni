public enum LogInEvent<Session: Sendable>: Sendable {
    case dismiss
    case forgotPassword
    case logIn(Session)
}
