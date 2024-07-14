import Foundation

public enum CreateSpendingError: Error {
    case noSuchUser(Error)
    case validation(Error)
    case privacy(Error)
    case other(RepositoryError)
}

public enum DeleteSpendingError: Error {
    case noSuchSpending(Error)
    case privacy(Error)
    case other(RepositoryError)
}

public protocol SpendingInteractionsUseCase {
    func create(spending: Spending) async -> Result<SpendingsPreview, CreateSpendingError>
    func delete(spending: Spending.ID) async -> Result<SpendingsPreview, DeleteSpendingError>
}
