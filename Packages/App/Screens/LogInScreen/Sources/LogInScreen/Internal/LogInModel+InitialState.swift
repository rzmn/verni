extension LogInModel {
    static var initialState: LogInState {
        LogInState(
            email: "",
            password: "",
            canSubmitCredentials: true,
            bottomSheet: nil
        )
    }
}
