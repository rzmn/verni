import Foundation

struct SignUpState: Equatable {
    let email: String
    let password: String
    let passwordConfirmation: String
    let emailHint: String?
    let passwordHint: String?
    let passwordConfirmationHint: String?

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
