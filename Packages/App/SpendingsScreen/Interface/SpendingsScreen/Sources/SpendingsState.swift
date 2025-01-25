import Foundation
import Entities

public struct SpendingsState: Equatable, Sendable {
    public struct Item: Sendable, Equatable, Identifiable {
        public var user: AnyUser
        public var balance: [Currency: Amount]

        public var id: String {
            user.id
        }
        
        public init(user: AnyUser, balance: [Currency: Amount]) {
            self.user = user
            self.balance = balance
        }

        public var isPositive: Bool {
            (balance.first?.value ?? 0) > 0
        }

        public var amount: String {
            balance.map { (currency, value) in
                let value = abs(value)
                switch currency {
                case .usDollar:
                    return "$\(value)"
                case .euro:
                    return "€\(value)"
                case .russianRuble:
                    return "\(value)₽"
                case .unknown(let code):
                    return "\(value) \(code)"
                }
            }.joined(separator: " + ")
        }
    }

    public var previews: [Item]
    
    public init(previews: [Item]) {
        self.previews = previews
    }
}
