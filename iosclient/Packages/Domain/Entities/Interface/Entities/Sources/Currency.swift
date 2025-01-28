public enum Currency: Hashable, Sendable {
    case russianRuble
    case usDollar
    case euro
    case unknown(String)

    public var stringValue: String {
        switch self {
        case .russianRuble:
            return "RUB"
        case .usDollar:
            return "USD"
        case .euro:
            return "EUR"
        case .unknown(let string):
            return string
        }
    }
}
