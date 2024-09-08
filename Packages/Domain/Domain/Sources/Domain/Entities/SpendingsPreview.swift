import Foundation

public struct SpendingsPreview: Sendable {
    public let counterparty: User.ID
    public let balance: [Currency: Cost]

    public init(counterparty: User.ID, balance: [Currency: Cost]) {
        self.counterparty = counterparty
        self.balance = balance
    }
}
