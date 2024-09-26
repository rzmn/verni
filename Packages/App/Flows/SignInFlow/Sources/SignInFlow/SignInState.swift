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
