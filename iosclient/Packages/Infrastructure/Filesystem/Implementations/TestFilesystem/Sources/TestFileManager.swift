import Filesystem
import Foundation

public struct TestFileManagerOverAnother<Impl: Filesystem.FileManager> {
    public var createDirectoryBlock: (@Sendable (URL) throws(CreateDirectoryError) -> Bool)?
    public var createFileWithDataBlock: (@Sendable (URL, Data?) throws(CreateFileError) -> Void)?
    public var listDirectoryBlock: (@Sendable (URL, DirectoryMask) throws(ListDirectoryError) -> [URL])?
    public var removeItemBlock: (@Sendable (URL) throws(RemoveItemError) -> Void)?
    public var createFileBlock: (@Sendable (URL) throws(CreateFileError) -> Void)?
    public var readFileBlock: (@Sendable (URL) throws(ReadFileError) -> Data)?

    let impl: Impl

    public init(impl: Impl) {
        self.impl = impl
    }
}

extension TestFileManagerOverAnother: Filesystem.FileManager {
    public func createDirectory(at url: URL) throws(CreateDirectoryError) -> Bool {
        guard let createDirectoryBlock else {
            return try impl.createDirectory(at: url)
        }
        return try createDirectoryBlock(url)
    }
    
    public func listDirectory(at url: URL, mask: DirectoryMask) throws(ListDirectoryError) -> [URL] {
        guard let listDirectoryBlock else {
            return try impl.listDirectory(at: url, mask: mask)
        }
        return try listDirectoryBlock(url, mask)
    }

    public func createFile(at url: URL) throws(CreateFileError) {
        guard let createFileBlock else {
            return try impl.createFile(at: url)
        }
        return try createFileBlock(url)
    }

    public func createFile(at url: URL, content: Data?) throws(CreateFileError) {
        guard let createFileWithDataBlock else {
            return try impl.createFile(at: url, content: content)
        }
        return try createFileWithDataBlock(url, content)
    }

    public func removeItem(at url: URL) throws(RemoveItemError) {
        guard let removeItemBlock else {
            return try impl.removeItem(at: url)
        }
        return try removeItemBlock(url)
    }
    
    public func readFile(at url: URL) throws(ReadFileError) -> Data {
        guard let readFileBlock else {
            return try readFile(at: url)
        }
        return try readFileBlock(url)
    }
}
