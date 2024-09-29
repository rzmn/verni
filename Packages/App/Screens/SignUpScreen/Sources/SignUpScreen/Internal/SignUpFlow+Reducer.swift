extension SignUpModel {
    static var reducer: @MainActor (SignUpState, SignUpAction) -> SignUpState {
        return { state, action in
            switch action {
            case .emailTextChanged(let text):
                return SignUpState(state, email: text, emailHint: text.isEmpty ? .isEmpty : nil)
            case .passwordTextChanged(let text):
                return SignUpState(state, password: text, passwordHint: text.isEmpty ? .isEmpty : nil)
            case .passwordRepeatTextChanged(let text):
                return SignUpState(
                    state,
                    passwordConfirmation: text,
                    passwordConfirmationHint: text.isEmpty ? .isEmpty : nil
                )
            case .emailHintUpdated(let hint):
                return SignUpState(state, emailHint: hint)
            case .passwordHintUpdated(let hint):
                return SignUpState(state, passwordHint: hint)
            case .passwordRepeatHintUpdated(let hint):
                return SignUpState(state, passwordConfirmationHint: hint)
            case .spinner(let running):
                return SignUpState(state, isLoading: running)
            case .showSnackbar(let preset):
                return SignUpState(state, snackbar: preset)
            case .hideSnackbar:
                return SignUpState(state, snackbar: .some(nil))
            case .confirm:
                return state
            }
        }
    }
}
