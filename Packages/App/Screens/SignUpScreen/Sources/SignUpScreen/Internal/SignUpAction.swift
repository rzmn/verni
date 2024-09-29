internal import DesignSystem

enum SignUpAction {
    case emailTextChanged(String)
    case passwordTextChanged(String)
    case passwordRepeatTextChanged(String)

    case emailHintUpdated(SignUpState.CredentialHint)
    case passwordHintUpdated(SignUpState.CredentialHint)
    case passwordRepeatHintUpdated(SignUpState.CredentialHint)

    case spinner(Bool)
    case showSnackbar(Snackbar.Preset)
    case hideSnackbar

    case confirm
}
