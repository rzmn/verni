extension SignUpModel {
    static var initialState: SignUpState {
        SignUpState(
            email: "",
            password: "",
            passwordConfirmation: "",
            emailHint: .noHint,
            passwordHint: .noHint,
            passwordConfirmationHint: .noHint,
            isLoading: false,
            snackbar: nil
        )
    }
}
