import Domain
import Api

extension Currency {
    public init(dto: CurrencyDto) {
        switch dto {
        case "RUB":
            self = .russianRuble
        case "EUR":
            self = .euro
        case "USD":
            self = .usDollar
        default:
            self = .unknown(dto)
        }
    }
}
