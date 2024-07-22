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
