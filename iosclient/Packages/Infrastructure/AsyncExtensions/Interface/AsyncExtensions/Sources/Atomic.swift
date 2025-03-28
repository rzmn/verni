import Foundation

public final class Atomic<T>: Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private let value: T
    
    public init(value: T) {
        self.value = value
    }
    
    public func access<R>(_ block: (T) -> R) -> R {
        lock.lock()
        defer {
            lock.unlock()
        }
        return block(value)
    }
}
