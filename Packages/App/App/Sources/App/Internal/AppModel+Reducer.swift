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
                    return .launched(.anonymous(AnonymousState(session: session)))
                case .authenticated(let session):
                    return .launched(.authenticated(AuthenticatedState(session: session)))
                }
            case .onAuthorized(let session):
                return .launched(.authenticated(AuthenticatedState(session: session)))
            case .logout(let session):
                return .launched(.anonymous(AnonymousState(session: session)))
            }
        }
    }
}
