import Api
import Domain
import Foundation
internal import ApiDomainConvenience

extension IdentifiableSpending {
    init(dto: IdentifiableDealDto) {
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
