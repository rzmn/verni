struct LoginState {
    let login: String
    let password: String

    let loginHint: String?
    let passwordHint: String?

    init(
        login: String,
        password: String
    ) {
        self.login = login
        self.password = password
        self.loginHint = nil
        self.passwordHint = nil
    }

    init(
        state: Self,
        login: String? = nil,
        password: String? = nil,
        loginHint: String?? = nil,
        passwordHint: String?? = nil
    ) {
        self.login = login ?? state.login
        self.password = password ?? state.password
        if case .some(let hint) = loginHint {
            self.loginHint = hint
        } else {
            self.loginHint = state.loginHint
        }
        if case .some(let hint) = passwordHint {
            self.passwordHint = hint
        } else {
            self.passwordHint = state.passwordHint
        }
    }
}
