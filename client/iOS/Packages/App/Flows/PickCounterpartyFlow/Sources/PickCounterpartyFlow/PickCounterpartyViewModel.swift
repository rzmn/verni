import Domain
import Combine
import Foundation

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
            .receive(on: RunLoop.main)
            .assign(to: &$state)
    }

    func reload(friends: [FriendshipKind: [User]]) {
        content = .loaded([PickCounterpartyState.Section](friends: friends))
    }

    func reload(error: GeneralError) {
        switch error {
        case .noConnection:
            content = .failed(
                previous: state.content,
                PickCounterpartyState.Failure(
                    hint: "no_connection_hint".localized,
                    iconName: "network.slash"
                )
            )
        case .notAuthorized:
            content = .failed(
                previous: state.content,
                PickCounterpartyState.Failure(
                    hint: "alert_title_unauthorized".localized,
                    iconName: "network.slash"
                )
            )
        case .other:
            content = .failed(
                previous: state.content,
                PickCounterpartyState.Failure(
                    hint: "unknown_error_hint".localized,
                    iconName: "exclamationmark.triangle"
                )
            )
        }
    }
}
