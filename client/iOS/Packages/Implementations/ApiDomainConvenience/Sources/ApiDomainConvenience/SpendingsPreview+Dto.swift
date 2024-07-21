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
                    dict[Currency(dto: item.key)] = Decimal(item.value) / 100
                }
            )
        )
    }
}
