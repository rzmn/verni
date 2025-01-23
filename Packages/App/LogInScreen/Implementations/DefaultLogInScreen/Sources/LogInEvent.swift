import DI

public enum LogInEvent: Sendable {
    case dismiss
    case forgotPassword
    case logIn(AuthenticatedDomainLayerSession)
}
