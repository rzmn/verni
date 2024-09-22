public protocol SpendingsOfflineRepository: Sendable {
    func getSpendingCounterparties() async -> [SpendingsPreview]?
    func getSpendingsHistory(counterparty: User.Identifier) async -> [IdentifiableSpending]?
}
