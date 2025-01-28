import AppLayer
internal import Convenience

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
            case .loggedOut(let session):
                return .launched(.anonymous(anonymousState(session: session)))
            case .logoutRequested:
                return state
            case .selectTabAnonymous(let tab):
                guard case .launched(let launched) = state else {
                    return state
                }
                guard case .anonymous(let anonymous) = launched else {
                    return state
                }
                return .launched(.anonymous(modify(anonymous) { $0.tab = tab }))
            case .selectTabAuthenticated(let tab):
                guard case .launched(let launched) = state else {
                    return state
                }
                guard case .authenticated(let authenticated) = launched else {
                    return state
                }
                return .launched(.authenticated(modify(authenticated) { $0.tab = tab }))
            case .addExpense:
                return state
            case .unauthorized(let reason):
                return modify(state) {
                    guard case .launched(let launched) = $0 else {
                        return
                    }
                    guard case .authenticated(var authenticated) = launched else {
                        return
                    }
                    authenticated.unauthenticatedFailure = reason
                    $0 = .launched(.authenticated(authenticated))
                }
            case .logIn:
                return state
            case .updateBottomSheet(let sheet):
                return modify(state) {
                    guard case .launched(let launched) = $0 else {
                        return
                    }
                    guard case .authenticated(var authenticated) = launched else {
                        return
                    }
                    authenticated.bottomSheet = sheet
                    $0 = .launched(.authenticated(authenticated))
                }
            }
        }
    }

    @MainActor private static func anonymousState(session: AnySandboxAppSession) -> AnonymousState {
        let authState = AnonymousState.AuthState()
        return AnonymousState(
            session: session,
            tabs: [
                .auth(authState)
            ],
            tab: .auth(authState)
        )
    }

    @MainActor private static func authenticatedState(session: AnyHostedAppSession) -> AuthenticatedState {
        AuthenticatedState(
            session: session,
            tabs: [
                .item(.spendings),
                .addExpense,
                .item(.profile)
            ],
            tab: .spendings,
            bottomSheet: nil,
            unauthenticatedFailure: nil
        )
    }
}
