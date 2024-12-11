import Foundation

protocol Printer: Sendable {
    // swiftlint:disable:next no_direct_standard_out_logs
    func print(_ message: String)
}

private struct PrinterWithCurrentDate: Printer {
    private let formatter: DateFormatter

    init() {
        let formatter = DateFormatter()
#if DEBUG
        formatter.dateFormat = "HH:mm:ss"
#else
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
#endif
        self.formatter = formatter
    }

    // swiftlint:disable:next no_direct_standard_out_logs
    func print(_ message: String) {
        // swiftlint:disable:next no_direct_standard_out_logs
#if DEBUG
        Swift.print("[verni] \(formatter.string(from: Date())) \(message)")
#else
        Swift.print("\(formatter.string(from: Date())) \(message)")
#endif
        
    }
}

public struct Logger: Sendable {
    public static let shared = Logger()

#if DEBUG
    public var severity: Severity = .debug
#else
    public var severity: Severity = .info
#endif

    private let printer: Printer
    private let prefix: String
    public var logBlock: (String, Severity) -> Void {
        return { message, severity in
            // swiftlint:disable:next no_direct_standard_out_logs
#if DEBUG
            let prefix = prefix.count < 4 ? prefix + Array(repeating: "➖", count: 4 - prefix.count) : prefix
#endif
            printer.print("\(severity) \(prefix)\(message)")
        }
    }

    init(severity: Severity = .debug, printer: Printer = PrinterWithCurrentDate(), prefix: String = "") {
        self.severity = severity
        self.printer = printer
        self.prefix = prefix
    }

    public func with(prefix: String) -> Logger {
        Logger(severity: severity, printer: printer, prefix: "\(logger.prefix)\(prefix)")
    }
}
