import Foundation
internal import DesignSystem

struct SignInState: Equatable, Sendable {
    let email: String
    let password: String
    let emailHint: String?
    let presentingSignUp: Bool
    let presentingSignIn: Bool
    let isLoading: Bool
    let snackbar: Snackbar.Preset?

    init(
        email: String,
        password: String,
        emailHint: String?,
        presentingSignUp: Bool,
        presentingSignIn: Bool,
        isLoading: Bool,
        snackbar: Snackbar.Preset?
    ) {
        self.email = email
        self.password = password
        self.emailHint = emailHint
        self.presentingSignUp = presentingSignUp
        self.presentingSignIn = presentingSignIn
        self.isLoading = isLoading
        self.snackbar = snackbar
    }

    init(
        _ state: Self,
        email: String? = nil,
        password: String? = nil,
        emailHint: String?? = nil,
        presentingSignUp: Bool? = nil,
        presentingSignIn: Bool? = nil,
        isLoading: Bool? = nil,
        snackbar: Snackbar.Preset?? = nil
    ) {
        self.email = email ?? state.email
        self.password = password ?? state.password
        self.emailHint = emailHint == nil ? state.emailHint : emailHint?.flatMap { $0 }
        self.presentingSignUp = presentingSignUp ?? state.presentingSignUp
        self.presentingSignIn = presentingSignIn ?? state.presentingSignIn
        self.isLoading = isLoading ?? state.isLoading
        self.snackbar = snackbar == nil ? state.snackbar : snackbar?.flatMap { $0 }
    }

    var canConfirm: Bool {
        if email.isEmpty || password.isEmpty {
            return false
        }
        if emailHint != nil {
            return false
        }
        return true
    }
}
