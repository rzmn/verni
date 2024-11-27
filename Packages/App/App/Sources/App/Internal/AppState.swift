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
    enum Tab {
        case spendings
        case profile
    }
    @EquatableByAddress var session: AuthenticatedPresentationLayerSession
    var tabs: [Tab]
    var tab: Tab
}

struct AnonymousState: Equatable, Sendable {
    struct AuthState: Equatable {
        var loggingIn: Bool
    }
    enum Tab: Equatable {
        case auth(AuthState)
    }
    @EquatableByAddress var session: AnonymousPresentationLayerSession
    var tabs: [Tab]
    var tab: Tab
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
