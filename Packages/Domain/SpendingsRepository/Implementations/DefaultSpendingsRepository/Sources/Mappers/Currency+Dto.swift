import Entities

extension Currency {
    public init(dto: String) {
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
