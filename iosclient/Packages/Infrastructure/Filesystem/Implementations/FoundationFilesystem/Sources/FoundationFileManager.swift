import Filesystem
import Foundation
import Logging

internal import Convenience

typealias FileManager = Filesystem.FileManager

public struct FoundationFileManager {
    public let logger: Logger
    var fileManager: Foundation.FileManager {
        .default
    }

    public init(logger: Logger) {
        self.logger = logger
    }
}

extension FoundationFileManager: FileManager {
    @discardableResult
    public func createDirectory(at url: URL) throws(CreateDirectoryError) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: url.path(), isDirectory: &isDirectory)
        guard !exists else {
            if isDirectory.boolValue {
                logI { "directory url \(url) already exists" }
                return false
            } else {
                logW { "directory \(url) is referring to file" }
                throw .urlIsReferringToFile
            }
        }
        do {
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
            logI { "created directory at \(url)" }
            return true
        } catch {
            logE { "failed to create directory at \(url) error: \(error)" }
            throw .internal(error)
        }
    }

    public func createFile(at url: URL, content: Data?) throws(CreateFileError) {
        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: url.path(), isDirectory: &isDirectory)
        guard !exists else {
            if isDirectory.boolValue {
                logW { "file url \(url) is referring to directory" }
                throw .urlIsReferringToDirectory
            } else {
                logI { "file \(url) already exists" }
                throw .alreadyExists
            }
        }
        let ok = fileManager.createFile(
            atPath: url.path(),
            contents: content
        )
        guard ok else {
            logE { "failed to create file at \(url)" }
            throw .internal(
                InternalError.error(
                    "underlying file manager did not return success"
                )
            )
        }
        logI { "created file at \(url)" }
    }

    public func listDirectory(at url: URL, mask: DirectoryMask) throws(ListDirectoryError) -> [URL] {
        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: url.path(), isDirectory: &isDirectory)
        guard exists else {
            logI { "directory \(url) does not exists" }
            throw .noSuchDirectory
        }
        guard isDirectory.boolValue else {
            logW { "directory \(url) is referring to file" }
            throw .urlIsReferringToFile
        }
        let content: [URL]
        do {
            content = try fileManager
                .contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                .filter { url in
                    var isDirectory = ObjCBool(true)
                    _ = fileManager.fileExists(atPath: url.path(), isDirectory: &isDirectory)
                    if isDirectory.boolValue {
                        return mask.contains(.directory)
                    } else {
                        return mask.contains(.file)
                    }
                }
                .map { url in
                    URL(
                        filePath: modify(url.path()) {
                            if $0 != "/" && $0.hasSuffix("/") {
                                _ = $0.popLast()
                            }
                        }
                    )
                }
        } catch {
            logE { "failed to list directory \(url) error: \(error)" }
            throw .internal(error)
        }
        return content
    }

    public func removeItem(at url: URL) throws(RemoveItemError) {
        let exists = fileManager.fileExists(atPath: url.path())
        guard exists else {
            logI { "item \(url) does not exists" }
            return
        }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            logE { "failed remove item \(url) error: \(error)" }
            throw .internal(error)
        }
    }
}

extension FoundationFileManager: Loggable {}
