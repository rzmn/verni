import DesignSystem
import Entities
internal import Convenience

public struct LaunchingState: Equatable, Sendable {
    public var session: AnySharedAppSession
    
    public init(session: AnySharedAppSession) {
        self.session = session
    }
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
    public enum UserPreview: Equatable {
        case pending(User)
        case ready(User, any UserPreviewScreenProvider)
        
        var user: User {
            switch self {
            case .pending(let user), .ready(let user, _):
                return user
            }
        }
        
        public static func == (lhs: AuthenticatedState.UserPreview, rhs: AuthenticatedState.UserPreview) -> Bool {
            lhs.user == rhs.user
        }
    }
    
    public var session: AnyHostedAppSession
    public var externalUserPreview: UserPreview?
    public var tabs: [Tab]
    public var tab: TabItem
    public var bottomSheet: AlertBottomSheetPreset?
    public var unauthenticatedFailure: String?

    public var tabItems: [TabItem] {
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
    
    public init(
        session: AnyHostedAppSession,
        tabs: [Tab],
        tab: TabItem,
        bottomSheet: AlertBottomSheetPreset?,
        unauthenticatedFailure: String?
    ) {
        self.session = session
        self.tabs = tabs
        self.tab = tab
        self.bottomSheet = bottomSheet
        self.unauthenticatedFailure = unauthenticatedFailure
    }
}

public struct AnonymousState: Equatable, Sendable {
    public struct AuthState: Equatable, Sendable {
        public init() {}
    }
    public enum Tab: Equatable, Sendable {
        case auth(AuthState)
    }
    public var session: AnySandboxAppSession
    public var tabs: [Tab]
    public var tab: Tab
    
    public init(
        session: AnySandboxAppSession,
        tabs: [Tab],
        tab: Tab
    ) {
        self.session = session
        self.tabs = tabs
        self.tab = tab
    }
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
