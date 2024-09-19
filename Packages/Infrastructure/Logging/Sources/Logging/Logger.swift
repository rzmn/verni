import Foundation

protocol Printer: Sendable {
    // swiftlint:disable:next no_direct_standard_out_logs
    func print(_ message: String)
}

private struct PrinterWithCurrentDate: Printer {
    private let formatter: DateFormatter

    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        self.formatter = formatter
    }

    // swiftlint:disable:next no_direct_standard_out_logs
    func print(_ message: String) {
        // swiftlint:disable:next no_direct_standard_out_logs
        Swift.print("\(formatter.string(from: Date())) \(message)")
    }
}

public struct Logger: Sendable {
    public static let shared = Logger()

    public var severity: Severity = .debug

    private let printer: Printer
    private let prefix: String
    public var logBlock: (String) -> Void {
        // swiftlint:disable:next no_direct_standard_out_logs
        { printer.print("\(prefix) \($0)") }
    }

    init(severity: Severity = .debug, printer: Printer = PrinterWithCurrentDate(), prefix: String = "") {
        self.severity = severity
        self.printer = printer
        self.prefix = prefix
    }

    public func with(prefix: String) -> Logger {
        Logger(severity: severity, printer: printer, prefix: "\(prefix) \(logger.prefix)")
    }
}
