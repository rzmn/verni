import Foundation
import Combine

public enum GetSpendingsHistoryError: Error {
    case noSuchCounterparty(Error)
    case other(GeneralError)
}

public protocol SpendingsRepository {
    func getSpendingCounterparties() async -> Result<[SpendingsPreview], GeneralError>
    func getSpendingsHistory(counterparty: User.ID) async -> Result<[IdentifiableSpending], GetSpendingsHistoryError>

    var spendingCounterpartiesUpdated: AnyPublisher<Void, Never> { get }
    var spendingsHistoryUpdated: AnyPublisher<User.ID, Never> { get }
}

public protocol SpendingsOfflineRepository {
    func getSpendingCounterparties() async -> [SpendingsPreview]?
    func getSpendingsHistory(counterparty: User.ID) async -> [IdentifiableSpending]?
}

public protocol SpendingsOfflineMutableRepository: SpendingsOfflineRepository {
    func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async
    func updateSpendingsHistory(counterparty: User.ID, history: [IdentifiableSpending]) async
}
