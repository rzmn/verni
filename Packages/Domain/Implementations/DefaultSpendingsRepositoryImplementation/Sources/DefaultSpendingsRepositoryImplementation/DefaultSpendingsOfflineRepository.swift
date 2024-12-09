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
        await persistency[Schema.spendingCounterparties.unkeyed].flatMap {
            $0.map(SpendingsPreview.init)
        }
    }

    public func getSpendingsHistory(counterparty: User.Identifier) async -> [IdentifiableSpending]? {
        await persistency[Schema.spendingsHistory.index(for: counterparty)].flatMap {
            $0.map(IdentifiableSpending.init)
        }
    }
}

extension DefaultSpendingsOfflineRepository: SpendingsOfflineMutableRepository {
    public func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async {
        await persistency.update(value: counterparties.map(BalanceDto.init), for: Schema.spendingCounterparties.unkeyed)
    }

    public func updateSpendingsHistory(counterparty: User.Identifier, history: [IdentifiableSpending]) async {
        await persistency.update(
            value: history.map(IdentifiableExpenseDto.init),
            for: Schema.spendingsHistory.index(for: counterparty)
        )
    }
}
