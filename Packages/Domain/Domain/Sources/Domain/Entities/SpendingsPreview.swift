import Foundation

public struct SpendingsPreview: Sendable, Equatable {
    public let counterparty: User.Identifier
    public let balance: [Currency: Cost]

    public init(counterparty: User.Identifier, balance: [Currency: Cost]) {
        self.counterparty = counterparty
        self.balance = balance
    }
}
