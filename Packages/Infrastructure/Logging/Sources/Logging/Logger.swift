import Foundation

public protocol Logger: Sendable {
    func logE(_ messageBlock: () -> String)
    func logI(_ messageBlock: () -> String)
    func logD(_ messageBlock: () -> String)

    func with(prefix: String) -> Self
}
