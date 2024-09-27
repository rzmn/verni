import Domain
import AppBase
internal import DesignSystem

@MainActor struct SignInAction: Action {
    enum Kind {
        case openSignInCredentialsForm
        case closeSignInCredentialsForm
        case signInCredentialsFormVisible(visible: Bool)

        case openSignUpCredentialsForm
        case closeSignUpCredentialsForm
        case signUpCredentialsFormVisible(visible: Bool)

        case emailTextChanged(String)
        case passwordTextChanged(String)

        case spinner(Bool)
        case showSnackbar(Snackbar.Preset)
        case hideSnackbar

        case confirmSignIn
    }
    let kind: Kind
    private let runner: @MainActor () -> Void

    static func action(kind: Kind, runner: @MainActor @escaping () -> Void = {}) -> Self {
        Self(kind: kind, runner: runner)
    }

    func run() {
        runner()
    }
}
