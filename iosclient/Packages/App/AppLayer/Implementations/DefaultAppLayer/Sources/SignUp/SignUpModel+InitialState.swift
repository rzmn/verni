import SignUpScreen
import Foundation

extension SignUpModel {
    static var initialState: SignUpState {
        SignUpState(
            email: "",
            password: "",
            passwordRepeat: "",
            canSubmitCredentials: false,
            signUpInProgress: false,
            bottomSheet: nil,
            sessionId: UUID()
        )
    }
}
