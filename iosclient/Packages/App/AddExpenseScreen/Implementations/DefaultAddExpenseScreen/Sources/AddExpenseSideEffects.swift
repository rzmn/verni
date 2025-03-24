import Entities
import AddExpenseScreen
import SpendingsRepository
import AppBase
import UIKit

@MainActor final class AddExpenseSideEffects: Sendable {
    private unowned let store: Store<AddExpenseState, AddExpenseAction>
    private let spendingsRepository: SpendingsRepository
    private let dataSource: AddExpenseDataSource

    init(
        store: Store<AddExpenseState, AddExpenseAction>,
        dataSource: AddExpenseDataSource,
        spendingsRepository: SpendingsRepository
    ) {
        self.store = store
        self.spendingsRepository = spendingsRepository
        self.dataSource = dataSource
    }
}

extension AddExpenseSideEffects: ActionHandler {
    var id: String {
        "\(AddExpenseSideEffects.self)"
    }

    func handle(_ action: AddExpenseAction) {
        switch action {
        case .submit:
            createSpending(state: store.state)
        case .appeared:
            subscribeToUpdates()
        default:
            break
        }
    }
    
    private func createSpending(state: AddExpenseState) {
        guard let counterparty = state.counterparty else {
            return
        }
        Task {
            let groups = await dataSource.groups
            guard let group = groups.first(where: { $0.counterparty.id == counterparty.id }) else {
                return
            }
            do {
                try await spendingsRepository.createSpending(
                    in: group.group.id,
                    displayName: state.title,
                    currency: state.currency,
                    amount: state.amount,
                    shares: {
                        switch state.splitRule {
                        case .equally:
                            return [
                                Spending.Share(
                                    userId: counterparty.id,
                                    amount: state.amount / 2 * (state.paidByHost ? -1 : +1)
                                ),
                                Spending.Share(
                                    userId: dataSource.hostId,
                                    amount: state.amount / 2 * (state.paidByHost ? +1 : -1)
                                )
                            ]
                        case .full:
                            return [
                                Spending.Share(
                                    userId: counterparty.id,
                                    amount: state.amount * (state.paidByHost ? -1 : +1)
                                ),
                                Spending.Share(
                                    userId: dataSource.hostId,
                                    amount: state.amount * (state.paidByHost ? +1 : -1)
                                )
                            ]
                        }
                    }()
                )
                store.dispatch(.expenseAdded)
            } catch {
                store.dispatch(.errorOccured("\(error)"))
            }
        }
    }
    
    private func subscribeToUpdates() {
        Task {
            let reload: @Sendable () -> Void = { [weak self] in
                guard let self else { return }
                Task {
                    await store.dispatch(
                        .availableCounterpartiesUpdated(
                            await dataSource.groups.map(\.counterparty)
                        )
                    )
                }
            }
            await spendingsRepository
                .updates
                .subscribeWeak(self) { event in
                    reload()
                }
        }
    }
}
