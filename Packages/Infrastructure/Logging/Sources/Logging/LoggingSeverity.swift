public enum LoggingSeverity: Int, Sendable, Comparable {
    case error = 0
    case warning = 1
    case info = 2
    case debug = 3

    public static func < (lhs: LoggingSeverity, rhs: LoggingSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
