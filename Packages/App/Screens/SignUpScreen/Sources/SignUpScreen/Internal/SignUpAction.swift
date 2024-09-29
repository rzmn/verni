internal import DesignSystem

enum SignUpAction {
    case emailTextChanged(String)
    case passwordTextChanged(String)
    case passwordRepeatTextChanged(String)

    case spinner(Bool)
    case showSnackbar(Snackbar.Preset)
    case hideSnackbar

    case confirm
}
