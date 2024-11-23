import DI

public enum LogInEvent: Sendable {
    case dismiss
    case createAccount
    case logIn(AuthenticatedDomainLayerSession)
}
