import DI

enum AppAction: Sendable {
    case launch
    case launched(AppDependencies)
    case selectTab(UnauthenticatedState.TabState)
    case changeSignInStackVisibility(visible: Bool)
    case changeSignInStack(stack: [UnauthenticatedState.AccountTabState.SignInStackElement])
    case acceptedSignInOffer
    case onCreateAccount
    case onCloseSignIn
    case onAuthorized(ActiveSessionDIContainer)
}
