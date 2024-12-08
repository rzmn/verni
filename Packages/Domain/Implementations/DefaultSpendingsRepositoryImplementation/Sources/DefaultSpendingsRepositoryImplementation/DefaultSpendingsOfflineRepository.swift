import Domain
import PersistentStorage
internal import ApiDomainConvenience
internal import DataTransferObjects

public actor DefaultSpendingsOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultSpendingsOfflineRepository: SpendingsOfflineRepository {
    public func getSpendingCounterparties() async -> [SpendingsPreview]? {
        await persistency[Schemas.spendingCounterparties.unkeyedIndex].flatMap {
            $0.map(SpendingsPreview.init)
        }
    }

    public func getSpendingsHistory(counterparty: User.Identifier) async -> [IdentifiableSpending]? {
        await persistency[Schemas.spendingsHistory.index(for: counterparty)].flatMap {
            $0.map(IdentifiableSpending.init)
        }
    }
}

extension DefaultSpendingsOfflineRepository: SpendingsOfflineMutableRepository {
    public func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async {
        await persistency.update(value: counterparties.map(BalanceDto.init), for: Schemas.spendingCounterparties.unkeyedIndex)
    }

    public func updateSpendingsHistory(counterparty: User.Identifier, history: [IdentifiableSpending]) async {
        await persistency.update(
            value: history.map(IdentifiableExpenseDto.init),
            for: Schemas.spendingsHistory.index(for: counterparty)
        )
    }
}
