import Entities
import SpendingsScreen
import SpendingsRepository
import UsersRepository
import AppBase

@MainActor final class SpendingsSideEffects: Sendable {
    private unowned let store: Store<SpendingsState, SpendingsAction>
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository
    private let dataSource: SpendingsDataSource

    init(
        store: Store<SpendingsState, SpendingsAction>,
        spendingsRepository: SpendingsRepository,
        dataSource: SpendingsDataSource,
        usersRepository: UsersRepository
    ) {
        self.store = store
        self.spendingsRepository = spendingsRepository
        self.usersRepository = usersRepository
        self.dataSource = dataSource
    }
}

extension SpendingsSideEffects: ActionHandler {
    var id: String {
        "\(SpendingsSideEffects.self)"
    }

    func handle(_ action: SpendingsAction) {
        switch action {
        case .onAppear:
            subscribeToUpdates()
        case .onSearchTap:
            break
        case .onOverallBalanceTap:
            break
        case .onGroupTap, .balanceUpdated:
            break
        }
    }
    
    private func subscribeToUpdates() {
        Task {
            let reload: @Sendable () -> Void = { [weak self] in
                guard let self else { return }
                Task {
                    let spendings = await dataSource.spendings
                    await store.dispatch(.balanceUpdated(spendings))
                }
            }            
            await usersRepository.updates
                .subscribeWeak(self) { events in
                    reload()
                }
            await spendingsRepository
                .updates
                .subscribeWeak(self) { events in
                    reload()
                }
        }
    }
}
