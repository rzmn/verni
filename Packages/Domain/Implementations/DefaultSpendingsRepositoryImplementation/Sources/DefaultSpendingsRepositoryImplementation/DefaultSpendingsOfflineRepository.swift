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
        await persistency.getSpendingCounterparties().flatMap {
            $0.map(SpendingsPreview.init)
        }
    }

    public func getSpendingsHistory(counterparty: User.ID) async -> [IdentifiableSpending]? {
        await persistency.getSpendingsHistory(counterparty: counterparty).flatMap {
            $0.map(IdentifiableSpending.init)
        }
    }
}

extension DefaultSpendingsOfflineRepository: SpendingsOfflineMutableRepository {
    public func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async {
        await persistency.updateSpendingCounterparties(counterparties.map(SpendingsPreviewDto.init))
    }

    public func updateSpendingsHistory(counterparty: User.ID, history: [IdentifiableSpending]) async {
        await persistency.updateSpendingsHistory(
            counterparty: counterparty,
            history: history.map(IdentifiableDealDto.init)
        )
    }
}
