import Combine
import Domain
import Foundation

@MainActor class AccountViewModel {
    @Published var state: AccountState

    @Published private var content: Loadable<Profile, String>

    init(profile: Profile?) {
        let initial: AccountState
        if let profile {
            initial = AccountState(
                info: .loaded(profile)
            )
        } else {
            initial = AccountState(info: .initial)
        }
        state = initial
        content = initial.info
        setupStateBuilder()
    }

    private func setupStateBuilder() {
        $content
            .map {
                AccountState(info: $0)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$state)
    }

    func setLoading() {
        content = .loading(previous: content)
    }

    func reload(profile: Profile) {
        content = .loaded(profile)
    }

    func subscribeTo(profilePublisher: AnyPublisher<Profile, Never>) {
        profilePublisher
            .map(Loadable.loaded)
            .assign(to: &$content)
    }
}
