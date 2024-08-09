import Domain

struct AccountState: Equatable {
    let info: Loadable<Profile, String>

    static var initial: Self {
        AccountState(info: .initial)
    }
}
