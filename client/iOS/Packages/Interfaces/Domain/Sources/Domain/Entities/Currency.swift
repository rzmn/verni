public enum Currency: Hashable {
    case russianRuble
    case unknown(String)

    public var stringValue: String {
        switch self {
        case .russianRuble:
            return "RUB"
        case .unknown(let string):
            return string
        }
    }
}
