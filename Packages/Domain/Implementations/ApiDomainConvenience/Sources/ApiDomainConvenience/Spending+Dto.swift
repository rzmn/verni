import Api
import Domain
import Foundation
import DataTransferObjects

extension Spending {
    public init(dto: DealDto) {
        self.init(
            date: Date(timeIntervalSince1970: TimeInterval(dto.timestamp)),
            details: dto.details,
            cost: Cost(dto: dto.cost),
            currency: Currency(dto: dto.currency),
            participants: dto.spendings.reduce(
                into: [:], { dict, dto in
                    dict[dto.userId] = Cost(dto: dto.cost)
                }
            )
        )
    }
}

extension DealDto {
    public init(domain: Spending) {
        self.init(
            timestamp: Int64(domain.date.timeIntervalSince1970),
            details: domain.details,
            cost: CostDto(cost: domain.cost),
            currency: domain.currency.stringValue,
            spendings: domain.participants.map { (key: User.Identifier, value: Cost) in
                SpendingDto(userId: key, cost: CostDto(cost: value))
            }
        )
    }
}
