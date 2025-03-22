import LogInScreen

extension LogInModel {
    static var initialState: LogInState {
        LogInState(
            email: "",
            password: "",
            logInInProgress: false
        )
    }
}
