import Domain

struct FriendsState {
    struct Content {
        let upcomingRequests: [User]
        let pendingRequests: [User]
        let friends: [User]
    }
    struct Failure: Error {
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
}
