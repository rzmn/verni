import Foundation
import Domain
import Api
import DataTransferObjects

extension SpendingsPreview {
    public init(dto: SpendingsPreviewDto) {
        self.init(
            counterparty: dto.counterparty,
            balance: dto.balance.reduce(
                into: [:], { dict, item in
                    dict[Currency(dto: item.key)] = Cost(dto: item.value)
                }
            )
        )
    }
}

extension SpendingsPreviewDto {
    public init(domain preview: SpendingsPreview) {
        self.init(
            counterparty: preview.counterparty,
            balance: preview.balance.reduce(into: [:], { dict, item in
                dict[item.key.stringValue] = CostDto(cost: item.value)
            })
        )
    }
}
