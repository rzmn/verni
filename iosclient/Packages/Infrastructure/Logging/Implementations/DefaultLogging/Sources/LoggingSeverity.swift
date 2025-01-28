extension Logger {
    public enum Severity: Int, Sendable, Comparable, CustomStringConvertible {
        case error = 0
        case warning = 1
        case info = 2
        case debug = 3

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        public var description: String {
            switch self {
            case .error:
                return "🔴"
            case .warning:
                return "🟡"
            case .info:
                return "⚪️"
            case .debug:
                return "⚫️"
            }
        }
    }
}
