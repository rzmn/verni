import Foundation
import Entities

public struct SpendingsState: Equatable, Sendable {
    public struct Item: Sendable, Equatable, Identifiable {
        public var id: SpendingGroup.Identifier
        public var image: Image.Identifier?
        public var name: String
        public var balance: [Currency: Amount]
        
        public init(
            id: SpendingGroup.Identifier,
            image: Image.Identifier? = nil,
            name: String,
            balance: [Currency: Amount]
        ) {
            self.id = id
            self.image = image
            self.name = name
            self.balance = balance
        }

        public var isPositive: Bool {
            (balance.first?.value ?? 0) >= 0
        }

        public var amount: String? {
            if balance.isEmpty {
                return nil
            } else {
                return balance.map { (currency, value) in
                    currency.formatted(amount: abs(value))
                }.joined(separator: " + ")
            }
        }
    }

    public var previews: [Item]
    
    public init(previews: [Item]) {
        self.previews = previews
    }
}
