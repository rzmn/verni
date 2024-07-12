import Domain

struct UserState {
    let user: User

    init(user: User) {
        self.user = user
    }

    init(
        _ state: Self,
        user: User? = nil
    ) {
        self.user = user ?? state.user
    }
}
