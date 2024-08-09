import Foundation

struct SignInState: Equatable {
    let email: String
    let password: String
    let emailHint: String?

    var canConfirm: Bool {
        if email.isEmpty || password.isEmpty {
            return false
        }
        if emailHint != nil {
            return false
        }
        return true
    }

    static var initial: Self {
        SignInState(email: "", password: "", emailHint: nil)
    }
}
