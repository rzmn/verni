import Foundation

public struct ListDirectoryMask: OptionSet, Sendable {
    public static let file = ListDirectoryMask(rawValue: 1 << 0)
    public static let directory = ListDirectoryMask(rawValue: 1 << 1)
    
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public protocol PathManager: Sendable {
    func createDirectory(at url: URL) throws
    func listDirectory(at url: URL, mask: ListDirectoryMask) throws -> [URL]
    func removeItem(at url: URL) throws
}

public struct DefaultPathManager {
    public init() {}
}

extension DefaultPathManager: PathManager {
    public func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
    }
    
    public func listDirectory(at url: URL, mask: ListDirectoryMask) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .filter { url in
                var isDirectory = ObjCBool(true)
                let exists = FileManager.default.fileExists(atPath: url.path(), isDirectory: &isDirectory)
                guard exists else {
                    return false
                }
                if isDirectory.boolValue {
                    return mask.contains(.directory)
                } else {
                    return mask.contains(.file)
                }
            }
    }
    
    public func removeItem(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
