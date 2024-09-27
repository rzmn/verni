extension SignUpFlow {
    static var reducer: @MainActor (SignUpState, SignUpAction.Kind) -> SignUpState {
        return { state, action in
            switch action {
            case .emailTextChanged(let text):
                return SignUpState(state, email: text)
            case .passwordTextChanged(let text):
                return SignUpState(state, password: text)
            case .passwordRepeatTextChanged(let text):
                return SignUpState(state, passwordConfirmation: text)
            case .spinner(let running):
                return SignUpState(state, isLoading: running)
            case .showSnackbar(let preset):
                return SignUpState(state, snackbar: preset)
            case .hideSnackbar:
                return SignUpState(state, snackbar: .some(nil))
            case .confirmSignUp:
                return state
            case .closeSignUp:
                return state
            }
        }
    }
}
