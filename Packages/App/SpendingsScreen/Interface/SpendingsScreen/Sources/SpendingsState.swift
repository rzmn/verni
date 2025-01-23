import Foundation
import Entities

public struct SpendingsState: Equatable, Sendable {
    public enum PreviewsLoadingFailureReason: Sendable, Equatable {
        case noInternet
    }

    public struct Item: Sendable, Equatable, Identifiable {
        let user: User
        let balance: [Currency: Amount]

        public var id: String {
            user.id
        }

        var isPositive: Bool {
            (balance.first?.value ?? 0) > 0
        }

        var amount: String {
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

    public var previews: Loadable<[Item], PreviewsLoadingFailureReason>
    
    public init(previews: Loadable<[Item], PreviewsLoadingFailureReason>) {
        self.previews = previews
    }
}
