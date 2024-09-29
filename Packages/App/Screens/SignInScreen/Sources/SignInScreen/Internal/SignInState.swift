import Foundation
internal import DesignSystem

extension SignInState.CredentialHint {
    var textFieldHint: TextFieldFormatHint? {
        switch self {
        case .noHint, .isEmpty:
            return nil
        case .message(let hint):
            return hint
        }
    }
}

struct SignInState: Equatable, Sendable {
    enum CredentialHint: Sendable, Equatable {
        case noHint
        case isEmpty
        case message(TextFieldFormatHint)

        var isAcceptable: Bool {
            switch self {
            case .isEmpty:
                return false
            case .noHint:
                return true
            case .message(let hint):
                switch hint {
                case .acceptable, .warning:
                    return true
                case .unacceptable:
                    return false
                }
            }
        }
    }

    let email: String
    let password: String
    let emailHint: CredentialHint
    let isLoading: Bool
    let snackbar: Snackbar.Preset?

    init(
        email: String,
        password: String,
        emailHint: CredentialHint,
        isLoading: Bool,
        snackbar: Snackbar.Preset?
    ) {
        self.email = email
        self.password = password
        self.emailHint = emailHint
        self.isLoading = isLoading
        self.snackbar = snackbar
    }

    init(
        _ state: Self,
        email: String? = nil,
        password: String? = nil,
        emailHint: CredentialHint? = nil,
        presentingSignUp: Bool? = nil,
        presentingSignIn: Bool? = nil,
        isLoading: Bool? = nil,
        snackbar: Snackbar.Preset?? = nil
    ) {
        self.email = email ?? state.email
        self.password = password ?? state.password
        self.emailHint = emailHint ?? state.emailHint
        self.isLoading = isLoading ?? state.isLoading
        self.snackbar = snackbar == nil ? state.snackbar : snackbar?.flatMap { $0 }
    }

    var canConfirm: Bool {
        if email.isEmpty || password.isEmpty {
            return false
        }
        guard emailHint.isAcceptable else {
            return false
        }
        return true
    }
}
