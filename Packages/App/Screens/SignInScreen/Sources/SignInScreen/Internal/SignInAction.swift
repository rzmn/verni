internal import DesignSystem

enum SignInAction {
    case emailTextChanged(String)
    case passwordTextChanged(String)

    case spinner(Bool)
    case showSnackbar(Snackbar.Preset)
    case hideSnackbar

    case confirm
    case createAccount
    case close
}
