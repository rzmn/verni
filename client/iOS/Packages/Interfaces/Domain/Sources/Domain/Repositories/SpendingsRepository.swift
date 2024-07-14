import Foundation

public protocol SpendingsRepository {
    func getSpendingCounterparties() async -> Result<[SpendingsPreview], RepositoryError>
    func getSpendingsHistory(counterparty: User.ID) async -> Result<[IdentifiableSpending], RepositoryError>
}
