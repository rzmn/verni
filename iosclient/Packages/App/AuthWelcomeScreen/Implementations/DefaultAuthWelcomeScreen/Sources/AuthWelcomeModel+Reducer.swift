import AuthWelcomeScreen

extension AuthWelcomeModel {
    static var reducer: @MainActor (AuthWelcomeState, AuthWelcomeAction) -> AuthWelcomeState {
        return { state, _ in
            state
        }
    }
}
