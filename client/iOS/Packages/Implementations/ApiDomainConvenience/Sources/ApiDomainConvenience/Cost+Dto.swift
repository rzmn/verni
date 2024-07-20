import Foundation
import Api
import Domain

extension Decimal {
    public init(dto: CostDto) {
        self = Decimal(dto) / 100
    }
}

extension CostDto {
    public init(cost: Cost) {
        self = Int64((NSDecimalNumber(decimal: cost).doubleValue * 100))
    }
}
