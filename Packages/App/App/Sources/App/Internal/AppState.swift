import DI
internal import Base

struct LaunchingState: Equatable, Sendable {}

enum LaunchedState: Equatable, Sendable {
    case authenticated(AuthenticatedState)
    case anonymous(AnonymousState)

    var authenticated: AuthenticatedState? {
        guard case .authenticated(let authenticated) = self else {
            return nil
        }
        return authenticated
    }

    var anonymous: AnonymousState? {
        guard case .anonymous(let anonymous) = self else {
            return nil
        }
        return anonymous
    }
}

struct AuthenticatedState: Equatable, Sendable {
    @EquatableByAddress var session: AuthenticatedPresentationLayerSession
}

struct AnonymousState: Equatable, Sendable {
    @EquatableByAddress var session: AnonymousPresentationLayerSession
}

enum AppState: Equatable, Sendable {
    case launching(LaunchingState)
    case launched(LaunchedState)

    var launching: LaunchingState? {
        guard case .launching(let launching) = self else {
            return nil
        }
        return launching
    }

    var launched: LaunchedState? {
        guard case .launched(let state) = self else {
            return nil
        }
        return state
    }
}
