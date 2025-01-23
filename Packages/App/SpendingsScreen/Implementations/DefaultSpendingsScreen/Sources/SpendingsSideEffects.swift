import Entities
import SpendingsScreen
import SpendingsRepository
import AppBase

@MainActor final class SpendingsSideEffects: Sendable {
    private unowned let store: Store<SpendingsState, SpendingsAction>
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository
    private var shouldUseAlreadyLoadedBalance = false

    init(
        store: Store<SpendingsState, SpendingsAction>,
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository
    ) {
        self.store = store
        self.spendingsRepository = spendingsRepository
        self.usersRepository = usersRepository
    }
}

extension SpendingsSideEffects: ActionHandler {
    var id: String {
        "\(SpendingsSideEffects.self)"
    }

    func handle(_ action: SpendingsAction) {
        switch action {
        case .onSearchTap:
            break
        case .onOverallBalanceTap:
            break
        case .onRefreshBalance:
            onRefreshBalance()
        case .onUserTap, .balanceUpdated:
            break
        }
    }

    private func onRefreshBalance() {
        Task {
            await refreshBalance()
        }
    }

    private func refreshBalance() async {
        guard !shouldUseAlreadyLoadedBalance else {
            return
        }
        let preview: [SpendingsPreview]
        do {
            preview = try await spendingsRepository.refreshSpendingCounterparties()
        } catch {
            return
        }
        let users: [User.Identifier: User]
        do {
            users = try await usersRepository
                .getUsers(ids: preview.map(\.counterparty))
                .reduce(into: [:]) { dict, user in
                    dict[user.id] = user
                }
        } catch {
            return
        }
        shouldUseAlreadyLoadedBalance = true
        store.dispatch(
            .balanceUpdated(
                preview.compactMap { item in
                    guard let user = users[item.counterparty] else {
                        return nil
                    }
                    return SpendingsState.Item(
                        user: user,
                        balance: item.balance
                    )
                }
            )
        )
    }
}
