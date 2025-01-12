import Foundation
import Api
import Domain

extension Decimal {
    public init(dto: Int64) {
        self = Decimal(dto) / 100
    }
}

extension Int64 {
    public init(amount: Amount) {
        self = Int64((NSDecimalNumber(decimal: amount).doubleValue * 100))
    }
}
