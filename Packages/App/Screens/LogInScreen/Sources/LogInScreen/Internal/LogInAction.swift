import DI
internal import DesignSystem

enum LogInAction {
    case onTapBack
    case passwordTextChanged(String)
    case emailTextChanged(String)
    case onForgotPasswordTap
    
    case onLogInTap
    case onLoggingInStarted
    case onLoggingInFailed
    case onUpdateBottomSheet(AlertBottomSheetPreset?)
    case loggedIn(AuthenticatedDomainLayerSession)
}
