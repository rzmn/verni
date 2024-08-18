import Domain

struct AccountState: Equatable {
    let info: Loadable<Profile, String>
}
