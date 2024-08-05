import Foundation

struct SignInState: Equatable {
    let email: String
    let password: String
    let emailHint: String?

    static var initial: Self {
        SignInState(email: "", password: "", emailHint: nil)
    }
}
