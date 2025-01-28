import Entities
import DesignSystem

public enum LogInAction<Session: Sendable>: Sendable {
    case onTapBack
    case passwordTextChanged(String)
    case emailTextChanged(String)
    case onForgotPasswordTap

    case onLogInTap
    case onLoggingInStarted
    case onLoggingInFailed
    case onUpdateBottomSheet(AlertBottomSheetPreset?)
    case loggedIn(Session)
}
