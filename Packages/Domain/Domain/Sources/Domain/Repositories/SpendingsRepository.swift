import Foundation
import AsyncExtensions

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
        counterparty: User.Identifier
    ) async throws(GetSpendingsHistoryError) -> [IdentifiableSpending]

    func getSpending(id: Spending.Identifier) async throws(GetSpendingError) -> Spending

    func spendingCounterpartiesUpdated() async -> any AsyncBroadcast<[SpendingsPreview]>
    func spendingsHistoryUpdated(for id: User.Identifier) async -> any AsyncBroadcast<[IdentifiableSpending]>
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
