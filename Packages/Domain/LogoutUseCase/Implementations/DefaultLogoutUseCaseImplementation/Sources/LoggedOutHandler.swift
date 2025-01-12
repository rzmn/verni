actor LoggedOutHandler {
    private var loggedOut = false

    func allowLogout() -> Bool {
        let allow = !loggedOut
        loggedOut = true
        return allow
    }
}
