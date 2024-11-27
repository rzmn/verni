import DI

extension AppModel {
    static var reducer: @MainActor @Sendable (AppState, AppAction) -> AppState {
        return { state, action in
            switch action {
            case .launch:
                return state
            case .launched(let session):
                switch session {
                case .anonymous(let session):
                    return .launched(.anonymous(anonymousState(session: session)))
                case .authenticated(let session):
                    return .launched(.authenticated(authenticatedState(session: session)))
                }
            case .onAuthorized(let session):
                return .launched(.authenticated(authenticatedState(session: session)))
            case .logout(let session):
                return .launched(.anonymous(anonymousState(session: session)))
            case .loggingIn(let loggingIn):
                guard case .launched(let launched) = state else {
                    return state
                }
                guard case .anonymous(let anonymous) = launched else {
                    return state
                }
                return .launched(.anonymous(anonymousState(session: anonymous.session, loggingIn: loggingIn)))
            }
        }
    }
    
    @MainActor private static func anonymousState(session: AnonymousPresentationLayerSession, loggingIn: Bool = false) -> AnonymousState {
        let authState = AnonymousState.AuthState(loggingIn: loggingIn)
        return AnonymousState(
            session: session,
            tabs: [
                .auth(authState)
            ],
            tab: .auth(authState)
        )
    }
    
    @MainActor private static func authenticatedState(session: AuthenticatedPresentationLayerSession) -> AuthenticatedState {
        AuthenticatedState(
            session: session,
            tabs: [
                .spendings,
                .profile
            ],
            tab: .profile
        )
    }
}
