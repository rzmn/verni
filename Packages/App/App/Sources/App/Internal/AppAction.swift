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
    
    case loggingIn(Bool)
}
