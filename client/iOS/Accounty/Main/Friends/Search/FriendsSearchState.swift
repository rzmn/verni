import Domain

struct FriendsSearchState {
    let content: Loadable<[User], String>

    init(content: Loadable<[User], String>) {
        self.content = content
    }

    init(
        _ state: Self,
        content: Loadable<[User], String>? = nil
    ) {
        self.content = content ?? state.content
    }
}
