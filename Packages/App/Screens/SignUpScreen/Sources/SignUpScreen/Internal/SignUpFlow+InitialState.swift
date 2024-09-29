extension SignUpModel {
    static var initialState: SignUpState {
        SignUpState(
            email: "",
            password: "",
            passwordConfirmation: "",
            emailHint: nil,
            passwordHint: nil,
            passwordConfirmationHint: nil,
            isLoading: false,
            snackbar: nil
        )
    }
}
