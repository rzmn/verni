import Domain
import AppBase

struct FriendsState {
    struct Content: Equatable {
        let upcomingRequests: [User]
        let pendingRequests: [User]
        let friends: [User]
    }
    struct Failure: Error, Equatable {
        let hint: String
        let iconName: String?
    }
    let content: Loadable<Content, Failure>

    init(content: Loadable<Content, Failure>) {
        self.content = content
    }

    init(
        _ state: Self,
        content: Loadable<Content, Failure>? = nil
    ) {
        self.content = content ?? state.content
    }

    static var initial: Self {
        FriendsState(content: .initial)
    }
}
