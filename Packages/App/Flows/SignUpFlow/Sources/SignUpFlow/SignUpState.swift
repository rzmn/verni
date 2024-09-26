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
