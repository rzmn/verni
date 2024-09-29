import Foundation
internal import DesignSystem

struct SignUpState: Sendable, Equatable {
    enum CredentialHint: Sendable, Equatable {
        case isEmpty
        case noHint
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
    let passwordConfirmation: String
    let emailHint: CredentialHint
    let passwordHint: CredentialHint
    let passwordConfirmationHint: CredentialHint
    let isLoading: Bool
    let snackbar: Snackbar.Preset?

    init(
        email: String,
        password: String,
        passwordConfirmation: String,
        emailHint: CredentialHint,
        passwordHint: CredentialHint,
        passwordConfirmationHint: CredentialHint,
        isLoading: Bool,
        snackbar: Snackbar.Preset?
    ) {
        self.email = email
        self.password = password
        self.passwordConfirmation = passwordConfirmation
        self.emailHint = emailHint
        self.passwordHint = passwordHint
        self.passwordConfirmationHint = passwordConfirmationHint
        self.isLoading = isLoading
        self.snackbar = snackbar
    }

    init(
        _ state: Self,
        email: String? = nil,
        password: String? = nil,
        passwordConfirmation: String? = nil,
        emailHint: CredentialHint? = nil,
        passwordHint: CredentialHint? = nil,
        passwordConfirmationHint: CredentialHint? = nil,
        isLoading: Bool? = nil,
        snackbar: Snackbar.Preset?? = nil
    ) {
        self.email = email ?? state.email
        self.password = password ?? state.password
        self.passwordConfirmation = passwordConfirmation ?? state.passwordConfirmation
        self.emailHint = emailHint ?? state.emailHint
        self.passwordHint = passwordHint ?? state.passwordHint
        self.passwordConfirmationHint = passwordConfirmationHint ?? state.passwordConfirmationHint
        self.isLoading = isLoading ?? state.isLoading
        self.snackbar = snackbar == nil ? state.snackbar : snackbar?.flatMap { $0 }
    }

    var canConfirm: Bool {
        if email.isEmpty || password.isEmpty || passwordConfirmation.isEmpty {
            return false
        }
        guard emailHint.isAcceptable && passwordHint.isAcceptable && passwordConfirmationHint.isAcceptable else {
            return false
        }
        return true
    }
}
