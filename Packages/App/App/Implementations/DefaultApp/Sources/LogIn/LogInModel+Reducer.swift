import LogInScreen
import App
internal import Convenience

extension LogInModel {
    static var reducer: @Sendable (LogInState, LogInAction<AnyHostedAppSession>) -> LogInState {
        return { state, action in
            switch action {
            case .onTapBack:
                return state
            case .passwordTextChanged(let text):
                return modify(state) {
                    $0.password = text
                }
            case .emailTextChanged(let text):
                return modify(state) {
                    $0.email = text
                }
            case .onForgotPasswordTap:
                return state
            case .onLogInTap:
                return state
            case .onLoggingInStarted:
                return modify(state) {
                    $0.canSubmitCredentials = false
                }
            case .onLoggingInFailed:
                return modify(state) {
                    $0.canSubmitCredentials = true
                }
            case .onUpdateBottomSheet(let preset):
                return modify(state) {
                    $0.bottomSheet = preset
                }
            case .loggedIn:
                return modify(state) {
                    $0.canSubmitCredentials = true
                }
            }
        }
    }
}
