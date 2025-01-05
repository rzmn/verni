import Foundation
import Domain
import Api

extension SpendingsPreview {
    public init(dto: BalanceDto) {
        self.init(
            counterparty: dto.counterparty,
            balance: dto.currencies.reduce(
                into: [:], { dict, item in
                    dict[Currency(dto: item.key)] = Cost(dto: item.value)
                }
            )
        )
    }
}

extension BalanceDto {
    public init(domain preview: SpendingsPreview) {
        self.init(
            counterparty: preview.counterparty,
            currencies: preview.balance.reduce(into: [:], { dict, item in
                dict[item.key.stringValue] = CostDto(cost: item.value)
            })
        )
    }
}
