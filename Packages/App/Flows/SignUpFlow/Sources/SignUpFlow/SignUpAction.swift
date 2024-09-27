import Domain
import AppBase
internal import DesignSystem

@MainActor struct SignUpAction: Action {
    enum Kind {
        case emailTextChanged(String)
        case passwordTextChanged(String)
        case passwordRepeatTextChanged(String)

        case spinner(Bool)
        case showSnackbar(Snackbar.Preset)
        case hideSnackbar

        case confirmSignUp
        case closeSignUp
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
