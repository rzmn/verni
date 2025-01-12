import Foundation
import Filesystem
import AsyncExtensions
import Logging
import QuartzCore

public protocol InfrastructureLayer: Sendable {
    var fileManager: Filesystem.FileManager { get }
    var taskFactory: TaskFactory { get }
    var logger: Logger { get }
    var time: TimeInterval { get }
    func nextId(isBlacklisted: (String) -> Bool) -> String
}

extension InfrastructureLayer {
    public var time: TimeInterval {
        CACurrentMediaTime()
    }
    
    public var timeMs: Int64 {
        Int64(UInt64(time) * MSEC_PER_SEC)
    }
    
    public func nextId() -> String {
        nextId { _ in false }
    }
    
    public func nextId(isBlacklisted: (String) -> Bool) -> String {
        repeat {
            let id = UUID().uuidString
            if isBlacklisted(id) {
                continue
            }
            return id
        } while true
    }
}
