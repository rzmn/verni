import Foundation

public protocol Loggable {
    var logger: Logger { get }

    func logE(_ messageBlock: () -> String)
    func logI(_ messageBlock: () -> String)
    func logD(_ messageBlock: () -> String)
}

public extension Loggable {
    var logger: Logger {
        .shared
    }

    func logE(_ messageBlock: () -> String) {
        Logging.log(logger, severity: .error, messageBlock)
    }

    func logI(_ messageBlock: () -> String) {
        Logging.log(logger, severity: .info, messageBlock)
    }

    func logD(_ messageBlock: () -> String) {
        Logging.log(logger, severity: .debug, messageBlock)
    }
}

extension Logger: Loggable {
    public var logger: Logger { self }
}

@inline(__always)
private func log(_ logger: Logger, severity: Logger.Severity, _ messageBlock: () -> String) {
    guard severity <= logger.severity else {
        return
    }
    logger.logBlock(messageBlock().replacingOccurrences(of: "\n", with: " \\n "), severity)
}
