import Api
import Domain
import Foundation

extension IdentifiableSpending {
    public init(dto: IdentifiableExpenseDto) {
        self.init(
            spending: Spending(
                dto: dto.deal
            ),
            id: dto.id
        )
    }
}

extension IdentifiableExpenseDto {
    public init(domain: IdentifiableSpending) {
        self.init(
            id: domain.id,
            deal: ExpenseDto(
                domain: domain.spending
            )
        )
    }
}
