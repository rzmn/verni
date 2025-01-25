import DomainLayer

public enum LogInEvent: Sendable {
    case dismiss
    case forgotPassword
    case logIn(HostedDomainLayer)
}
