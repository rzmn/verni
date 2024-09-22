import Foundation

public typealias Cost = Decimal

fileprivate extension Date {
    var byRoudingSeconds: Date {
        Date(timeIntervalSince1970: TimeInterval(Int64(timeIntervalSince1970)))
    }
}

public struct Spending: Equatable, Sendable {
    public let date: Date
    public let details: String
    public let cost: Cost
    public let currency: Currency
    public let participants: [User.Identifier: Cost]

    public init(date: Date, details: String, cost: Cost, currency: Currency, participants: [User.Identifier: Cost]) {
        self.date = date.byRoudingSeconds
        self.details = details
        self.cost = cost
        self.currency = currency
        self.participants = participants
    }
}

public struct IdentifiableSpending: Equatable, Sendable {
    public let spending: Spending
    public let id: Spending.Identifier

    public init(spending: Spending, id: Spending.Identifier) {
        self.spending = spending
        self.id = id
    }
}

extension Spending {
    public typealias Identifier = String
}
