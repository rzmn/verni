import Filesystem
import AsyncExtensions
import Logging

public protocol InfrastructureLayer: Sendable {
    var fileManager: FileManager { get }
    var taskFactory: TaskFactory { get }
    var logger: Logger { get }
}
