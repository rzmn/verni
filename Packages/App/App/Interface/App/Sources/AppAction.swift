import DesignSystem

public enum LaunchSession: Sendable {
    case anonymous(SandboxAppSession)
    case authenticated(HostedAppSession)
}

public enum AppAction: Sendable {
    case launch
    case launched(LaunchSession)

    case logoutRequested
    case loggedOut(SandboxAppSession)

    case logIn(HostedAppSession, AnonymousState)

    case onAuthorized(HostedAppSession)

    case addExpense
    case selectTabAnonymous(AnonymousState.Tab)
    case selectTabAuthenticated(AuthenticatedState.TabItem)
    case updateBottomSheet(AlertBottomSheetPreset?)
    case unauthorized(reason: String)
}
