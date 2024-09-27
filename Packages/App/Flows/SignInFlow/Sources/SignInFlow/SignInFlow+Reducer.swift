extension SignInFlow {
    static var reducer: @MainActor (SignInState, SignInAction.Kind) -> SignInState {
        return { state, action in
            switch action {
            case .openSignInCredentialsForm:
                return state
            case .closeSignInCredentialsForm:
                return state
            case .signInCredentialsFormVisible(let visible):
                return SignInState(state, presentingSignIn: visible)
            case .openSignUpCredentialsForm:
                return state
            case .closeSignUpCredentialsForm:
                return state
            case .signUpCredentialsFormVisible(let visible):
                return SignInState(state, presentingSignUp: visible)
            case .emailTextChanged(let email):
                return SignInState(state, email: email)
            case .passwordTextChanged(let password):
                return SignInState(state, password: password)
            case .spinner(let running):
                return SignInState(state, isLoading: running)
            case .showSnackbar(let preset):
                return SignInState(state, snackbar: preset)
            case .hideSnackbar:
                return SignInState(state, snackbar: .some(nil))
            case .confirmSignIn:
                return state
            }
        }
    }
}
