import DesignSystem
internal import Convenience

public struct LaunchingState: Equatable, Sendable {
    var session: AnySharedAppSession
}

public enum LaunchedState: Equatable, Sendable {
    case authenticated(AuthenticatedState)
    case anonymous(AnonymousState)

    public var authenticated: AuthenticatedState? {
        guard case .authenticated(let authenticated) = self else {
            return nil
        }
        return authenticated
    }

    public var anonymous: AnonymousState? {
        guard case .anonymous(let anonymous) = self else {
            return nil
        }
        return anonymous
    }
}

public struct AuthenticatedState: Equatable, Sendable {
    public enum Tab: Equatable, Sendable {
        case item(TabItem)
        case addExpense
    }
    public enum TabItem: Equatable, Identifiable, Sendable {
        case spendings
        case profile

        public var id: String {
            switch self {
            case .spendings:
                "spendings"
            case .profile:
                "profile"
            }
        }
    }
    public enum TabPosition {
        case exact
        case toTheLeft
        case toTheRight
    }
    var session: AnyHostedAppSession
    var tabs: [Tab]
    var tab: TabItem
    var bottomSheet: AlertBottomSheetPreset?
    var unauthenticatedFailure: String?

    var tabItems: [TabItem] {
        tabs.compactMap {
            switch $0 {
            case .addExpense:
                return nil
            case .item(let item):
                return item
            }
        }
    }

    func position(of tabItem: TabItem) -> TabPosition? {
        guard let center = tabs.firstIndex(of: .item(tab)), let index = tabs.firstIndex(of: .item(tabItem)) else {
            return nil
        }
        if center == index {
            return .exact
        } else if center < index {
            return .toTheRight
        } else {
            return .toTheLeft
        }
    }
}

public struct AnonymousState: Equatable, Sendable {
    public struct AuthState: Equatable, Sendable {
    }
    public enum Tab: Equatable, Sendable {
        case auth(AuthState)
    }
    var session: AnySandboxAppSession
    public var tabs: [Tab]
    public var tab: Tab
}

public enum AppState: Equatable, Sendable {
    case launching(LaunchingState)
    case launched(LaunchedState)

    public var launching: LaunchingState? {
        guard case .launching(let launching) = self else {
            return nil
        }
        return launching
    }

    public var launched: LaunchedState? {
        guard case .launched(let state) = self else {
            return nil
        }
        return state
    }
}

extension AppState: SharedAppSessionConvertible {
    public var shared: SharedAppSession {
        switch self {
        case .launching(let state):
            return state.session.value
        case .launched(let state):
            switch state {
            case .authenticated(let state):
                return state.session.value.shared
            case .anonymous(let state):
                return state.session.value.shared
            }
        }
    }
}
