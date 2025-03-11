import Foundation

public typealias Amount = Decimal
public typealias MsSince1970 = Int64

extension Amount {
    public var currencyFormatted: String {
        String(format: "%.2f", NSDecimalNumber(decimal: self).doubleValue)
    }
}

fileprivate extension Date {
    var byRoudingSeconds: Date {
        Date(timeIntervalSince1970: TimeInterval(Int64(timeIntervalSince1970)))
    }
}

public struct Spending: Equatable, Sendable {
    public let id: Identifier
    public let payload: Payload

    public struct Share: Equatable, Sendable {
        public let userId: User.Identifier
        public let amount: Amount

        public init(userId: User.Identifier, amount: Amount) {
            self.userId = userId
            self.amount = amount
        }
    }

    public struct Payload: Equatable, Sendable {
        public let name: String
        public let currency: Currency
        public let createdAt: MsSince1970
        public let amount: Amount
        public let shares: [Share]

        public init(
            name: String,
            currency: Currency,
            createdAt: MsSince1970,
            amount: Amount,
            shares: [Share]
        ) {
            self.name = name
            self.currency = currency
            self.createdAt = createdAt
            self.amount = amount
            self.shares = shares
        }
    }

    public init(id: Identifier, payload: Payload) {
        self.id = id
        self.payload = payload
    }
}

extension Spending {
    public typealias Identifier = String
}
