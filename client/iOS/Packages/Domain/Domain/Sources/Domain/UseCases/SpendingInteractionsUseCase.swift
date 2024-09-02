public enum CreateSpendingError: Error, Sendable {
    case noSuchUser(Error)
    case privacy(Error)
    case other(GeneralError)
}

public enum DeleteSpendingError: Error, Sendable {
    case noSuchSpending(Error)
    case privacy(Error)
    case other(GeneralError)
}

public protocol SpendingInteractionsUseCase: Sendable {
    func create(spending: Spending) async throws(CreateSpendingError)
    func delete(spending: Spending.ID) async throws(DeleteSpendingError)
}
