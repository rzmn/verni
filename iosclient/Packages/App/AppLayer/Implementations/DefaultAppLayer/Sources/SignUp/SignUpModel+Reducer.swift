import SignUpScreen
import AppLayer
internal import Convenience

extension SignUpModel {
    static var reducer: @Sendable (SignUpState, SignUpAction<AnyHostedAppSession>) -> SignUpState {
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
            case .passwordRepeatTextChanged(let text):
                return modify(state) {
                    $0.passwordRepeat = text
                }
            case .onSignUpTap:
                return state
            case .onSigningUpStarted:
                return modify(state) {
                    $0.signUpInProgress = true
                }
            case .onSigningUpFailed:
                return modify(state) {
                    $0.signUpInProgress = false
                }
            case .onUpdateBottomSheet(let preset):
                return modify(state) {
                    $0.bottomSheet = preset
                }
            case .signUp:
                return state
            case .emailHintChanged(let hint):
                return modify(state) {
                    $0.emailHint = hint
                }
            case .passwordHintChanged(let hint):
                return modify(state) {
                    $0.passwordHint = hint
                }
            case .passwordRepeatHintChanged(let hint):
                return modify(state) {
                    $0.passwordRepeatHint = hint
                }
            case .canSubmitCredentialsChanged(let canSubmitCredentials):
                return modify(state) {
                    $0.canSubmitCredentials = canSubmitCredentials
                }
            }
        }
    }
}
