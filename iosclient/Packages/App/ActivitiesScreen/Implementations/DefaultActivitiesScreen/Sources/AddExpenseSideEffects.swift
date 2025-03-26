import Entities
import ActivitiesScreen
import SpendingsRepository
import UsersRepository
import OperationsRepository
import AppBase
import UIKit

@MainActor final class AddExpenseSideEffects: Sendable {
    private unowned let store: Store<ActivitiesState, ActivitiesAction>
    private let operationsRepository: OperationsRepository
    private let usersRepository: UsersRepository
    private let spendingsRepository: SpendingsRepository

    init(
        store: Store<ActivitiesState, ActivitiesAction>,
        operationsRepository: OperationsRepository,
        usersRepository: UsersRepository,
        spendingsRepository: SpendingsRepository
    ) {
        self.store = store
        self.operationsRepository = operationsRepository
        self.usersRepository = usersRepository
        self.spendingsRepository = spendingsRepository
    }
}

extension AddExpenseSideEffects: ActionHandler {
    var id: String {
        "\(AddExpenseSideEffects.self)"
    }

    func handle(_ action: ActivitiesAction) {
        switch action {
        case .appeared:
            subscribeToUpdates()
        default:
            break
        }
    }
    
    private func subscribeToUpdates() {
        Task {
            let reload: @Sendable () -> Void = { [weak self] in
                guard let self else { return }
                Task {
                    await store.dispatch(
                        .onDataUpdated(operationsRepository.operations)
                    )
                }
            }
            await operationsRepository
                .updates
                .subscribeWeak(self) { event in
                    reload()
                }
        }
    }
}
