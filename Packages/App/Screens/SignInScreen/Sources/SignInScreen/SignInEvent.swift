import DI

public enum SignInEvent: Sendable {
    case canceled
    case routeToSignUp
    case signedIn(ActiveSessionDIContainer)
}
