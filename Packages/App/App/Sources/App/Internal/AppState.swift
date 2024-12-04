import DI
internal import DesignSystem
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
    enum Tab: Equatable {
        case item(TabItem)
        case addExpense
    }
    enum TabItem: Equatable, Identifiable {
        case spendings
        case profile
        
        var id: String {
            switch self {
            case .spendings:
                "spendings"
            case .profile:
                "profile"
            }
        }
    }
    enum TabPosition {
        case exact
        case toTheLeft
        case toTheRight
    }
    @EquatableByAddress var session: AuthenticatedPresentationLayerSession
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

struct AnonymousState: Equatable, Sendable {
    struct AuthState: Equatable {
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
