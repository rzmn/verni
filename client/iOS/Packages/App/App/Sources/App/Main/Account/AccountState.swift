import Domain

struct AccountState {
    let session: Loadable<User, String>

    init(session: Loadable<User, String>) {
        self.session = session
    }

    init(
        _ state: Self,
        session: Loadable<User, String>? = nil
    ) {
        self.session = session ?? state.session
    }
}
