import Foundation
import Entities

public struct SpendingsGroupState: Equatable, Sendable {
    public struct Item: Equatable, Sendable, Identifiable {
        public var id: String
        public var name: String
        public var currency: Currency
        public var createdAt: String
        public var amount: Amount
        public var diff: Amount
        
        public init(
            id: String,
            name: String,
            currency: Currency,
            createdAt: String,
            amount: Amount,
            diff: Amount
        ) {
            self.id = id
            self.name = name
            self.currency = currency
            self.createdAt = createdAt
            self.amount = amount
            self.diff = diff
        }
        
        var amountFormatted: String {
            currency.formatted(amount: amount)
        }
        
        var diffFormatted: String {
            currency.formatted(amount: abs(diff))
        }
    }
    
    public struct GroupPreview: Equatable, Sendable {
        public var image: Image.Identifier?
        public var name: String
        public var balance: [Currency: Amount]
        
        public init(
            image: Image.Identifier? = nil,
            name: String,
            balance: [Currency: Amount]
        ) {
            self.image = image
            self.name = name
            self.balance = balance
        }
    }
    
    public var preview: GroupPreview
    public var items: [Item]
    
    var balanceFormatted: String? {
        if preview.balance.isEmpty {
            return nil
        } else {
            return preview.balance.map { (currency, value) in
                currency.formatted(amount: value)
            }.joined(separator: " + ")
        }
    }
    
    public init(
        preview: GroupPreview,
        items: [Item]
    ) {
        self.preview = preview
        self.items = items
    }
}
