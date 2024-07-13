import Foundation

public class Logger {
    public static let shared = Logger()

    public var severity: Severity = .debug

    private let formatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()

    public lazy var logBlock: (String) -> Void = {
        print("\(self.formatter.string(from: Date())) [$v] \($0)")
    }

    var prefix = ""

    public func with(prefix: String) -> Logger {
        let logger = Logger()
        logger.severity = severity
        logger.prefix = "\(prefix)\(logger.prefix)"
        logger.logBlock = logBlock
        return logger
    }
}
