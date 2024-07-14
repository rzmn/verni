import Foundation

public struct Spending {
    let date: Date
    let details: String
    let cost: Decimal
    let currency: Currency
    let participants: [User.ID: Decimal]
}

public struct IdentifiableSpending {
    let spending: Spending
    let id: Spending
}

extension Spending {
    public typealias ID = String
}
