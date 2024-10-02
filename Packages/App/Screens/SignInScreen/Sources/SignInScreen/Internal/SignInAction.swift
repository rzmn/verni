internal import DesignSystem

enum SignInAction {
    case emailTextChanged(String)
    case passwordTextChanged(String)

    case emailHintUpdated(SignInState.CredentialHint)

    case spinner(Bool)
    case showSnackbar(Snackbar.Preset)
    case hideSnackbar

    case confirm
    case confirmFailedFeedback

    case createAccount
    case close
}
