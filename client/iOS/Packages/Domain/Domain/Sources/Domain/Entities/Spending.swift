import Foundation

public typealias Cost = Decimal

public struct Spending {
    public let date: Date
    public let details: String
    public let cost: Cost
    public let currency: Currency
    public let participants: [User.ID: Cost]

    public init(date: Date, details: String, cost: Cost, currency: Currency, participants: [User.ID: Cost]) {
        self.date = date
        self.details = details
        self.cost = cost
        self.currency = currency
        self.participants = participants
    }
}

public struct IdentifiableSpending {
    public let spending: Spending
    public let id: Spending.ID

    public init(spending: Spending, id: Spending.ID) {
        self.spending = spending
        self.id = id
    }
}

extension Spending {
    public typealias ID = String
}
