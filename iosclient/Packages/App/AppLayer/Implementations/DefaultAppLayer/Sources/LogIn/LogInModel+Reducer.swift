import LogInScreen
import AppLayer
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
                    $0.logInInProgress = true
                }
            case .onLoggingInFailed:
                return modify(state) {
                    $0.logInInProgress = false
                }
            case .onUpdateBottomSheet(let preset):
                return modify(state) {
                    $0.bottomSheet = preset
                }
            case .loggedIn:
                return state
            }
        }
    }
}
