import Domain
import Api
import DataTransferObjects

extension Currency {
    public init(dto: CurrencyDto) {
        switch dto {
        case "RUB":
            self = .russianRuble
        default:
            self = .unknown(dto)
        }
    }
}
