import Infrastructure
import Filesystem
import AsyncExtensions
import Logging
import TestAsyncExtensions
import FoundationFilesystem
import TestFilesystem
internal import DefaultLogging

private var isDebug: Bool {
#if DEBUG
    true
#else
    false
#endif
}

public struct TestInfrastructureLayer: InfrastructureLayer {
    public var testTaskFactory = TestTaskFactory()
    public var testFileManager = TestFileManagerOverAnother(impl: FoundationFileManager())

    public var taskFactory: TaskFactory {
        testTaskFactory
    }

    public var fileManager: FileManager {
        testFileManager
    }

    public var logger: Logging.Logger

    public init() {
        self.logger = DefaultLogging.Logger(
            severity: isDebug ? .debug : .info
        )
    }
}
