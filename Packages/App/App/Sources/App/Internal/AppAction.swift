import DI

enum LaunchSession {
    case anonymous(AnonymousPresentationLayerSession)
    case authenticated(AuthenticatedPresentationLayerSession)
}

enum AppAction: Sendable {
    case launch
    case logout(AnonymousPresentationLayerSession)
    case launched(LaunchSession)
    case onAuthorized(AuthenticatedPresentationLayerSession)

    case addExpense
    case selectTabAnonymous(AnonymousState.Tab)
    case selectTabAuthenticated(AuthenticatedState.TabItem)
    case loggingIn(Bool)
    case unauthorized(reason: String)
}
