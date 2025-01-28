import InfrastructureLayer
import Filesystem
import AsyncExtensions
import Logging
internal import DefaultLogging
internal import FoundationFilesystem
internal import DefaultAsyncExtensions
internal import LoggingExtensions

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
        let severity: DefaultLogging.Logger.Severity = isDebug ? .debug : .info
        self.logger = DefaultLogging.Logger(severity: severity)
        
        let internalLogger = logger
            .with(scope: .infrastructure)
        
        self.fileManager = FoundationFileManager(
            logger: internalLogger
                .with(scope: .filesystem)
        )
        self.taskFactory = DefaultTaskFactory()
        internalLogger.logI { "initialized default infrastructure" }
    }
}
