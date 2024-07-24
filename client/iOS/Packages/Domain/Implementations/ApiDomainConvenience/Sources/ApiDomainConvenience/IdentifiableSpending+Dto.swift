import Api
import Domain
import Foundation
import DataTransferObjects

extension IdentifiableSpending {
    public init(dto: IdentifiableDealDto) {
        self.init(
            spending: Spending(
                date: Date(timeIntervalSince1970: TimeInterval(dto.timestamp)),
                details: dto.details,
                cost: Cost(dto: dto.cost),
                currency: Currency(dto: dto.currency),
                participants: dto.spendings.reduce(
                    into: [:], { dict, dto in
                        dict[dto.userId] = Cost(dto: dto.cost)
                    }
                )
            ),
            id: dto.id
        )
    }
}

extension IdentifiableDealDto {
    public init(domain: IdentifiableSpending) {
        self.init(
            id: domain.id,
            deal: DealDto(
                timestamp: Int64(domain.spending.date.timeIntervalSince1970),
                details: domain.spending.details,
                cost: CostDto(cost: domain.spending.cost),
                currency: domain.spending.currency.stringValue,
                spendings: domain.spending.participants.map{ (key: User.ID, value: Cost) in
                    SpendingDto(userId: key, cost: CostDto(cost: value))
                }
            )
        )
    }
}
