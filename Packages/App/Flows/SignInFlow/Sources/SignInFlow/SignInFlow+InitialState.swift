extension SignInFlow {
    static var initialState: SignInState {
        SignInState(
            email: "",
            password: "",
            emailHint: nil,
            presentingSignUp: false,
            presentingSignIn: false,
            isLoading: false,
            snackbar: nil
        )
    }
}
