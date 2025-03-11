import Entities
import AddExpenseScreen
import SpendingsRepository
import AppBase
import UIKit

@MainActor final class AddExpenseSideEffects: Sendable {
    private unowned let store: Store<AddExpenseState, AddExpenseAction>
    private let spendingsRepository: SpendingsRepository
    private let groups: [OneToOneSpendingsGroup]
    private let hostId: User.Identifier

    init(
        store: Store<AddExpenseState, AddExpenseAction>,
        groups: [OneToOneSpendingsGroup],
        hostId: User.Identifier,
        spendingsRepository: SpendingsRepository
    ) {
        self.store = store
        self.spendingsRepository = spendingsRepository
        self.hostId = hostId
        self.groups = groups
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
        default:
            break
        }
    }
    
    private func createSpending(state: AddExpenseState) {
        guard let counterparty = state.counterparty else {
            return
        }
        guard let group = groups.first(where: { $0.counterparty.id == counterparty.id }) else {
            return
        }
        Task {
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
                                    userId: hostId,
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
                                    userId: hostId,
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
}
