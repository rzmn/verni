import Logging

public struct Logger: Sendable {
    let severity: Severity
    let logBlock: @Sendable (String, Severity) -> Void

    private let printer: Printer
    private let prefix: String

    public init(
        severity: Severity
    ) {
        self = Logger(
            severity: severity,
            printer: PrinterWithCurrentDate(),
            prefix: ""
        )
    }

    init(
        severity: Severity,
        printer: Printer,
        prefix: String
    ) {
        self.severity = severity
        self.logBlock = { message, severity in
#if DEBUG
            let prefix = prefix.count < 5 ? prefix + Array(repeating: "➖", count: 5 - prefix.count) : prefix
#endif
            // swiftlint:disable:next no_direct_standard_out_logs
            printer.print("\(severity) \(prefix)\(message)")
        }
        self.printer = printer
        self.prefix = prefix
    }
}

extension Logger: Logging.Logger {
    public func with(prefix: String) -> Logger {
        Logger(
            severity: severity,
            printer: printer,
            prefix: "\(self.prefix)\(prefix)"
        )
    }

    public func logE(_ messageBlock: () -> String) {
        log(self, severity: .error, messageBlock)
    }
    
    public func logW(_ messageBlock: () -> String) {
        log(self, severity: .warning, messageBlock)
    }

    public func logI(_ messageBlock: () -> String) {
        log(self, severity: .info, messageBlock)
    }

    public func logD(_ messageBlock: () -> String) {
        log(self, severity: .debug, messageBlock)
    }
}

@inline(__always)
private func log(_ logger: Logger, severity: Logger.Severity, _ messageBlock: () -> String) {
    guard severity <= logger.severity else {
        return
    }
    logger.logBlock(messageBlock().replacingOccurrences(of: "\n", with: " \\n "), severity)
}
