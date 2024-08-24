import Foundation
import Combine

public enum GetSpendingsHistoryError: Error {
    case noSuchCounterparty(Error)
    case other(GeneralError)
}

public protocol SpendingsRepository {
    @discardableResult
    func refreshSpendingCounterparties() async -> Result<[SpendingsPreview], GeneralError>

    @discardableResult
    func refreshSpendingsHistory(
        counterparty: User.ID
    ) async -> Result<[IdentifiableSpending], GetSpendingsHistoryError>

    func spendingCounterpartiesUpdated() async -> AnyPublisher<Void, Never>
    func spendingsHistoryUpdated(for id: User.ID) async -> AnyPublisher<Void, Never>
}

public protocol SpendingsOfflineRepository {
    func getSpendingCounterparties() async -> [SpendingsPreview]?
    func getSpendingsHistory(counterparty: User.ID) async -> [IdentifiableSpending]?
}

public protocol SpendingsOfflineMutableRepository: SpendingsOfflineRepository {
    func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async
    func updateSpendingsHistory(counterparty: User.ID, history: [IdentifiableSpending]) async
}
