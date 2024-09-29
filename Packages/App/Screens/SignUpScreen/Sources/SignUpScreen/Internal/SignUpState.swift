import Foundation
internal import DesignSystem

struct SignUpState: Sendable, Equatable {
    let email: String
    let password: String
    let passwordConfirmation: String
    let emailHint: String?
    let passwordHint: String?
    let passwordConfirmationHint: String?
    let isLoading: Bool
    let snackbar: Snackbar.Preset?

    init(
        email: String,
        password: String,
        passwordConfirmation: String,
        emailHint: String?,
        passwordHint: String?,
        passwordConfirmationHint: String?,
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
        emailHint: String?? = nil,
        passwordHint: String?? = nil,
        passwordConfirmationHint: String?? = nil,
        isLoading: Bool? = nil,
        snackbar: Snackbar.Preset?? = nil
    ) {
        self.email = email ?? state.email
        self.password = password ?? state.password
        self.passwordConfirmation = passwordConfirmation ?? state.passwordConfirmation
        self.emailHint = emailHint == nil ? state.emailHint : emailHint?.flatMap { $0 }
        self.passwordHint = passwordHint == nil ? state.passwordHint : passwordHint?.flatMap { $0 }
        self.passwordConfirmationHint = passwordConfirmationHint == nil ? state.passwordConfirmationHint : passwordConfirmationHint?.flatMap { $0 }
        self.isLoading = isLoading ?? state.isLoading
        self.snackbar = snackbar == nil ? state.snackbar : snackbar?.flatMap { $0 }
    }

    var canConfirm: Bool {
        if email.isEmpty || password.isEmpty || passwordConfirmation.isEmpty {
            return false
        }
        if emailHint != nil || passwordHint != nil || passwordConfirmationHint != nil {
            return false
        }
        return true
    }
}
