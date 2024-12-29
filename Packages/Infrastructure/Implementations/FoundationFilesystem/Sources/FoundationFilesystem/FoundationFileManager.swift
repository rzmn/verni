import Filesystem
import Foundation
internal import Base

typealias FileManager = Filesystem.FileManager

public struct FoundationFileManager {
    var fileManager: Foundation.FileManager {
        .default
    }

    public init() {}
}

extension FoundationFileManager: FileManager {
    @discardableResult
    public func createDirectory(at url: URL) throws(CreateDirectoryError) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: url.path(), isDirectory: &isDirectory)
        guard !exists else {
            if isDirectory.boolValue {
                return false
            } else {
                throw .urlIsReferringToFile
            }
        }
        do {
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
            return true
        } catch {
            throw .internal(error)
        }
    }

    public func createFile(at url: URL, content: Data?) throws(CreateFileError) {
        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: url.path(), isDirectory: &isDirectory)
        guard !exists else {
            if isDirectory.boolValue {
                throw .urlIsReferringToDirectory
            } else {
                throw .alreadyExists
            }
        }
        let ok = fileManager.createFile(
            atPath: url.path(),
            contents: content
        )
        guard ok else {
            throw .internal(
                InternalError.error(
                    "underlying file manager did not return success"
                )
            )
        }
    }

    public func listDirectory(at url: URL, mask: DirectoryMask) throws(ListDirectoryError) -> [URL] {
        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: url.path(), isDirectory: &isDirectory)
        guard exists else {
            throw .noSuchDirectory
        }
        guard isDirectory.boolValue else {
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
            throw .internal(error)
        }
        return content
    }

    public func removeItem(at url: URL) throws(RemoveItemError) {
        let exists = fileManager.fileExists(atPath: url.path())
        guard exists else {
            return
        }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw .internal(error)
        }
    }
}
