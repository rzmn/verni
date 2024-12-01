import DI
internal import DesignSystem

enum LaunchSession {
    case anonymous(AnonymousPresentationLayerSession)
    case authenticated(AuthenticatedPresentationLayerSession)
}

enum AppAction: Sendable {
    case launch
    case launched(LaunchSession)
    
    case logoutRequested
    case loggedOut(AnonymousPresentationLayerSession)
    
    case onAuthorized(AuthenticatedPresentationLayerSession)

    case addExpense
    case selectTabAnonymous(AnonymousState.Tab)
    case selectTabAuthenticated(AuthenticatedState.TabItem)
    case loggingIn(Bool)
    case updateBottomSheet(AlertBottomSheetPreset?)
    case unauthorized(reason: String)
}
