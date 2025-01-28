import Logging

public struct TestLogger {
    private let prefix: String
    
    public init(prefix: String = "") {
        self.prefix = prefix
    }
    
    private func doLog(_ prefix: String, message: String) {
        print("\(prefix): \(message)")
    }
}

extension TestLogger: Logger {
    public func logE(_ messageBlock: () -> String) {
        doLog(prefix + "[e]", message: messageBlock())
    }
    
    public func logW(_ messageBlock: () -> String) {
        doLog(prefix + "[w]", message: messageBlock())
    }
    
    public func logI(_ messageBlock: () -> String) {
        doLog(prefix + "[i]", message: messageBlock())
    }
    
    public func logD(_ messageBlock: () -> String) {
        doLog(prefix + "[d]", message: messageBlock())
    }
    
    public func with(prefix: String) -> TestLogger {
        TestLogger(prefix: self.prefix + prefix)
    }
}
