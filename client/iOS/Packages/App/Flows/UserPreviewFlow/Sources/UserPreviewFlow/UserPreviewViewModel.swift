import Foundation
import Domain
import Combine

fileprivate extension IdentifiableSpending {
    func preview(assuming hostId: User.ID) -> UserPreviewState.SpendingPreview? {
        guard let personalAmount = spending.participants[hostId] else {
            return nil
        }
        return UserPreviewState.SpendingPreview(
            id: id,
            date: spending.date,
            title: spending.details,
            iOwe: personalAmount > 0, 
            currency: spending.currency,
            personalAmount: personalAmount
        )
    }
}

@MainActor class UserPreviewViewModel {
    @Published var state: UserPreviewState

    @Published var user: User
    @Published var spendings: Loadable<[IdentifiableSpending], UserPreviewState.Failure>

    private let hostId: User.ID

    init(hostId: User.ID, counterparty: User, spendings: [IdentifiableSpending]?) async {
        self.hostId = hostId
        let initialSpendingPreviews = spendings.flatMap { spendings in
            spendings.compactMap {
                $0.preview(assuming: hostId)
            }
            .sorted { lhs, rhs in
                lhs.date > rhs.date
            }
        }
        let initial = UserPreviewState(
            user: counterparty,
            spenginds: initialSpendingPreviews.flatMap { .loaded($0) } ?? .initial
        )
        self.state = initial
        self.user = initial.user
        self.spendings = spendings.flatMap { .loaded($0) } ?? .initial

        setupStateBuilder()
    }

    private func setupStateBuilder() {
        Publishers.CombineLatest3($user, $spendings, Just(hostId))
            .map { value in
                let (user, spendings, hostId) = value
                return UserPreviewState(
                    user: user,
                    spenginds: spendings.mapValue { spendings in
                        spendings.compactMap {
                            $0.preview(assuming: hostId)
                        }
                        .sorted { lhs, rhs in
                            lhs.date > rhs.date
                        }
                    }
                )
            }
            .receive(on: RunLoop.main)
            .assign(to: &$state)
    }
}
