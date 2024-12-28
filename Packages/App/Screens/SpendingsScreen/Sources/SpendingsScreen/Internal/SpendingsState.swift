import Foundation
import Domain
internal import DesignSystem

struct SpendingsState: Equatable, Sendable {
    enum PreviewsLoadingFailureReason: Equatable {
        case noInternet
    }

    struct Item: Equatable, Identifiable {
        let user: User
        let balance: [Currency: Cost]

        var id: String {
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

    var previews: Loadable<[Item], PreviewsLoadingFailureReason>
}
