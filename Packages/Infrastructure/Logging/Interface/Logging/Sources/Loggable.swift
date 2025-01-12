import Foundation

public protocol Loggable {
    var logger: Logger { get }

    func logE(_ messageBlock: () -> String)
    func logI(_ messageBlock: () -> String)
    func logD(_ messageBlock: () -> String)
}

public extension Loggable {
    func logE(_ messageBlock: () -> String) {
        logger.logE(messageBlock)
    }

    func logI(_ messageBlock: () -> String) {
        logger.logI(messageBlock)
    }

    func logD(_ messageBlock: () -> String) {
        logger.logD(messageBlock)
    }
}
