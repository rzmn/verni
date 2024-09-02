import Foundation
import Combine

public enum GetSpendingsHistoryError: Error, Sendable {
    case noSuchCounterparty(Error)
    case other(GeneralError)
}

public enum GetSpendingError: Error, Sendable {
    case noSuchSpending(Error)
    case other(GeneralError)
}

public protocol SpendingsRepository: Sendable {
    @discardableResult
    func refreshSpendingCounterparties() async throws(GeneralError) -> [SpendingsPreview]

    @discardableResult
    func refreshSpendingsHistory(
        counterparty: User.ID
    ) async throws(GetSpendingsHistoryError) -> [IdentifiableSpending]

    func getSpending(id: Spending.ID) async throws(GetSpendingError) -> Spending

    func spendingCounterpartiesUpdated() async -> AnyPublisher<[SpendingsPreview], Never>
    func spendingsHistoryUpdated(for id: User.ID) async -> AnyPublisher<[IdentifiableSpending], Never>
}

public extension SpendingsRepository {
    @discardableResult
    func refreshSpendingCounterpartiesNoTypedThrow() async -> Result<[SpendingsPreview], GeneralError> {
        do {
            return .success(try await refreshSpendingCounterparties())
        } catch {
            return .failure(error)
        }
    }
}
