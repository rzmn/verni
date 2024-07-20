import Foundation
import Combine

public enum GetSpendingsHistoryError: Error {
    case noSuchCounterparty(Error)
    case other(GeneralError)
}

public protocol SpendingsRepository {
    func getSpendingCounterparties() async -> Result<[SpendingsPreview], GeneralError>
    func getSpendingsHistory(counterparty: User.ID) async -> Result<[IdentifiableSpending], GetSpendingsHistoryError>
    var spendingsUpdated: AnyPublisher<Void, Never> { get }
}
