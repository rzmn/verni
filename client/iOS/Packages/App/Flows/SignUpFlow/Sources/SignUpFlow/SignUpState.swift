import Foundation

struct SignUpState: Equatable {
    let email: String
    let password: String
    let passwordConfirmation: String
    let emailHint: String?
    let passwordHint: String?
    let passwordConfirmationHint: String?

    static var initial: Self {
        SignUpState(email: "", password: "", passwordConfirmation: "", emailHint: nil, passwordHint: nil, passwordConfirmationHint: nil)
    }
}
