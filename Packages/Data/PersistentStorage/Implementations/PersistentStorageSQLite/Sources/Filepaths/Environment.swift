import Filesystem
import Foundation
import Logging

struct Environment {
    let fileManager: Filesystem.FileManager
    let versionLabel: String
    let containerDirectory: URL
    
    init(
        logger: Logger,
        fileManager: Filesystem.FileManager,
        versionLabel: String,
        containerDirectory: URL
    ) throws {
        self.fileManager = fileManager
        self.versionLabel = versionLabel
        self.containerDirectory = containerDirectory.appending(path: "sqlite_\(versionLabel)")
        
        try prepare(logger: logger)
    }
    
    private func prepare(logger: Logger) throws {
        logger.logI { "preparing environment for sqlite \(versionLabel)" }
        do {
            try fileManager.createDirectory(at: containerDirectory)
        } catch {
            logger.logE { "failed to create db path manager, error: \(error)" }
            throw error
        }
        logger.logI { "created [version=\(versionLabel)] at \(containerDirectory)" }
    }
}
