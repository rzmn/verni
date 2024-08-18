import Domain
import Combine

fileprivate extension Array where Element == PickCounterpartyState.Section {
    init(friends: [FriendshipKind: [User]]) {
        self = [
            PickCounterpartyState.Section(
                kind: .existing,
                items: friends.values
                    .flatMap {
                        $0
                    }
                    .sorted { lhs, rhs in
                        lhs.id < rhs.id
                    }
            )
        ]
    }
}

@MainActor class PickCounterpartyViewModel {
    @Published var state: PickCounterpartyState

    @Published var content: Loadable<[PickCounterpartyState.Section], PickCounterpartyState.Failure>

    init(friends: [FriendshipKind: [User]]?) {
        let initial: PickCounterpartyState
        if let friends {
            initial = PickCounterpartyState(
                content: .loaded([PickCounterpartyState.Section](friends: friends))
            )
        } else {
            initial = PickCounterpartyState(
                content: .initial
            )
        }
        state = initial
        content = initial.content
        setupStateBuilder()
    }

    private func setupStateBuilder() {
        $content
            .map {
                PickCounterpartyState(content: $0)
            }
            .assign(to: &$state)
    }

    func reload(friends: [FriendshipKind: [User]]) {
        content = .loaded([PickCounterpartyState.Section](friends: friends))
    }
}
