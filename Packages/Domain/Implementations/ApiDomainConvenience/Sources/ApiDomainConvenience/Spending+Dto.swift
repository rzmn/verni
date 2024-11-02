import Api
import Domain
import Foundation
import DataTransferObjects

extension Spending {
    public init(dto: ExpenseDto) {
        self.init(
            date: Date(timeIntervalSince1970: TimeInterval(dto.timestamp)),
            details: dto.details,
            cost: Cost(dto: dto.total),
            currency: Currency(dto: dto.currency),
            participants: dto.shares.reduce(
                into: [:], { dict, dto in
                    dict[dto.userId] = Cost(dto: dto.cost)
                }
            )
        )
    }
}

extension ExpenseDto {
    public init(domain: Spending) {
        self.init(
            timestamp: Int64(domain.date.timeIntervalSince1970),
            details: domain.details,
            cost: CostDto(cost: domain.cost),
            currency: domain.currency.stringValue,
            shares: domain.participants.map { (key: User.Identifier, value: Cost) in
                ShareOfExpenseDto(userId: key, cost: CostDto(cost: value))
            },
            attachments: []
        )
    }
}
