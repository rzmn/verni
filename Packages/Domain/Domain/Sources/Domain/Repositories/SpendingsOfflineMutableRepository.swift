public protocol SpendingsOfflineMutableRepository: Sendable {
    func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async
    func updateSpendingsHistory(counterparty: User.ID, history: [IdentifiableSpending]) async
}
