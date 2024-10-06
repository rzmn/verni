import DI

struct LaunchingState: Equatable, Sendable {}

enum LaunchedState: Equatable, Sendable {
    case authenticated(AuthenticatedState)
    case unauthenticated(UnauthenticatedState)
}

struct AuthenticatedState: Equatable, Sendable {
    struct Session: Equatable, Sendable {
        let container: ActiveSessionDIContainer

        static func == (lhs: Session, rhs: Session) -> Bool {
            lhs.container.userId == rhs.container.userId
        }
    }
    let session: Session
}

struct UnauthenticatedState: Equatable, Sendable {
    struct AccountTabState: Hashable, Sendable {
        enum SignInStackElement: Hashable, Sendable {
            case createAccount
        }
        struct SignInStack: Hashable, Sendable {
            let elements: [SignInStackElement]
        }
        let signInStack: SignInStack
        let signInStackVisible: Bool
    }
    enum TabState: Hashable, Sendable, Identifiable {
        case account(AccountTabState)

        var id: String {
            switch self {
            case .account:
                return "account"
            }
        }
    }
    let tabs: [TabState]
    let tab: TabState
}

enum AppState: Equatable, Sendable {
    case launching(LaunchingState)
    case launched(AppDependencies, LaunchedState)

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.launching, .launching), (.launched, .launched):
            return true
        default:
            return false
        }
    }
}
