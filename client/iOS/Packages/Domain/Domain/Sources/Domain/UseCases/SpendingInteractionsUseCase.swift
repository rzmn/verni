import Foundation

public enum CreateSpendingError: Error {
    case noSuchUser(Error)
    case privacy(Error)
    case other(GeneralError)
}

public enum DeleteSpendingError: Error {
    case noSuchSpending(Error)
    case privacy(Error)
    case other(GeneralError)
}

public protocol SpendingInteractionsUseCase {
    func create(spending: Spending) async -> Result<Void, CreateSpendingError>
    func delete(spending: Spending.ID) async -> Result<Void, DeleteSpendingError>
}
