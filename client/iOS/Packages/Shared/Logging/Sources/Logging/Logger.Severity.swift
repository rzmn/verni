extension Logger {
    public enum Severity: Int, Comparable, CustomStringConvertible {
        case error = 0
        case info = 1
        case debug = 2

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        public var description: String {
            switch self {
            case .error:
                return "e"
            case .info:
                return "i"
            case .debug:
                return "d"
            }
        }
    }
}
