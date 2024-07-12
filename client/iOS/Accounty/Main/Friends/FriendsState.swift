import Domain

struct FriendsState {
    struct Content {
        let upcomingRequests: [User]
        let pendingRequests: [User]
        let friends: [User]
    }
    let content: Loadable<Content, String>

    init(content: Loadable<Content, String>) {
        self.content = content
    }

    init(
        _ state: Self,
        content: Loadable<Content, String>? = nil
    ) {
        self.content = content ?? state.content
    }
}
