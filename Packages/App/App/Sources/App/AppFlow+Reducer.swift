import DI

extension AppFlow {
    static func reducer<Session: Sendable>() -> @MainActor @Sendable (AppState<Session>, AppUserAction<Session>.Kind) -> AppState<Session> {
        return { state, _ in
            switch state {
            case .authenticated(let session):
                return .authenticated(session)
            case .unauthenticated:
                return .unauthenticated
            }
        }
    }
}
