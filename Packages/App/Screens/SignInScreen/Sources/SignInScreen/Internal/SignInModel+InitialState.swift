extension SignInModel {
    static var initialState: SignInState {
        SignInState(
            email: "",
            password: "",
            emailHint: .noHint,
            isLoading: false,
            snackbar: nil
        )
    }
}
