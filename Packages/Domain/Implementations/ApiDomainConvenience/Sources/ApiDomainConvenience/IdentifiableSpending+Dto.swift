import Api
import Domain
import Foundation
import DataTransferObjects

extension IdentifiableSpending {
    public init(dto: IdentifiableDealDto) {
        self.init(
            spending: Spending(
                dto: dto.deal
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
                domain: domain.spending
            )
        )
    }
}
