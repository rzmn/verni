import Domain
import PersistentStorage

public class DefaultSpendingsOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultSpendingsOfflineRepository: SpendingsOfflineRepository {
    public func getSpendingCounterparties() async -> [SpendingsPreview]? {
        await persistency.getSpendingCounterparties()
    }
    
    public func getSpendingsHistory(counterparty: User.ID) async -> [IdentifiableSpending]? {
        await persistency.getSpendingsHistory(counterparty: counterparty)
    }
}

extension DefaultSpendingsOfflineRepository: SpendingsOfflineMutableRepository {
    public func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async {
        await persistency.updateSpendingCounterparties(counterparties)
    }

    public func updateSpendingsHistory(counterparty: User.ID, history: [IdentifiableSpending]) async {
        await persistency.updateSpendingsHistory(counterparty: counterparty, history: history)
    }
}
