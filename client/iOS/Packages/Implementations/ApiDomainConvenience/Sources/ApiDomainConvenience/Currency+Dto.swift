import Domain
import Api

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
