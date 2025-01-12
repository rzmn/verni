import InfrastructureLayer
import Filesystem
import AsyncExtensions
import Logging
internal import DefaultLogging
internal import FoundationFilesystem
internal import DefaultAsyncExtensions

private var isDebug: Bool {
#if DEBUG
    true
#else
    false
#endif
}

public struct DefaultInfrastructureLayer: InfrastructureLayer {
    public var taskFactory: TaskFactory
    public var fileManager: FileManager
    public var logger: Logging.Logger

    public init() {
        self.fileManager = FoundationFileManager()
        self.taskFactory = DefaultTaskFactory()
        self.logger = DefaultLogging.Logger(
            severity: isDebug ? .debug : .info
        )
    }
}
