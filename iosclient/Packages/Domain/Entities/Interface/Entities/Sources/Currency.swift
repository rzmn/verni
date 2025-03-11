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

extension Currency {
    public var sign: String {
        switch self {
        case .russianRuble:
            return "₽"
        case .usDollar:
            return "$"
        case .euro:
            return "€"
        case .unknown(let string):
            return string
        }
    }
    
    public func formatted(amount: Amount) -> String {
        switch self {
        case .russianRuble:
            "\(amount.currencyFormatted)\(sign)"
        case .usDollar, .euro:
            "\(sign)\(amount.currencyFormatted)"
        case .unknown(let string):
            "\(amount.currencyFormatted)\(sign)"
        }
    }
}
