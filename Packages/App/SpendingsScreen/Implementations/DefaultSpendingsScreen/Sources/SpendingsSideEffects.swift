import Entities
import SpendingsScreen
import SpendingsRepository
import UsersRepository
import AppBase

@MainActor final class SpendingsSideEffects: Sendable {
    private unowned let store: Store<SpendingsState, SpendingsAction>
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository

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
        case .onUserTap, .balanceUpdated:
            break
        }
    }
}
