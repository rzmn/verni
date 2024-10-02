extension SignInModel {
    static var reducer: @MainActor (SignInState, SignInAction) -> SignInState {
        return { state, action in
            switch action {
            case .emailTextChanged(let email):
                return SignInState(state, email: email, emailHint: email.isEmpty ? .isEmpty : nil)
            case .passwordTextChanged(let password):
                return SignInState(state, password: password)
            case .emailHintUpdated(let hint):
                return SignInState(state, emailHint: hint)
            case .spinner(let running):
                return SignInState(state, isLoading: running)
            case .showSnackbar(let preset):
                return SignInState(state, snackbar: preset)
            case .hideSnackbar:
                return SignInState(state, snackbar: .some(nil))
            case .confirm:
                return state
            case .createAccount:
                return state
            case .confirmFailedFeedback:
                return SignInState(state, shakingCounter: state.shakingCounter + 1)
            case .close:
                return state
            }
        }
    }
}
