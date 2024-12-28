import Foundation

public protocol FileManager: Sendable {
    func createDirectory(
        at url: URL
    ) throws(CreateDirectoryError)

    func createFile(
        at url: URL,
        content: Data?
    ) throws(CreateFileError)

    func listDirectory(
        at url: URL,
        mask: DirectoryMask
    ) throws(ListDirectoryError) -> [URL]

    func removeItem(
        at url: URL
    ) throws(RemoveItemError)

    func createFile(
        at url: URL
    ) throws(CreateFileError)
}

extension FileManager {
    public func createFile(
        at url: URL
    ) throws(CreateFileError) {
        try createFile(at: url, content: nil)
    }
}
