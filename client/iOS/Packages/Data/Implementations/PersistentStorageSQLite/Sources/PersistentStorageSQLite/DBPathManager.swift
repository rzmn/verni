import Foundation
import Base

public struct DBPathManager: Sendable {
    struct Descriptor {
        let owner: String
        let container: URL

        var dbUrl: URL {
            container.appendingPathComponent(Constants.dbFilename)
        }
    }

    private enum Constants {
        static let containerDirName = "db"
        static let prefix = "s_v1_"
        static let dbFilename = "db.sqlite"
    }

    private let container: URL

    init(container: URL) throws {
        self.container = container.appendingPathComponent(Constants.containerDirName)
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(
            atPath: container.path,
            isDirectory: &isDirectory
        )
        if !exists {
            try FileManager.default.createDirectory(
                at: container,
                withIntermediateDirectories: true
            )
        } else if !isDirectory.boolValue {
            throw InternalError.error("already has a file at \(container)", underlying: nil)
        }
    }

    func create(owner: String) throws -> Descriptor {
        try invalidate(owner: owner)
        let url = url(for: owner)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return Descriptor(
            owner: owner,
            container: url
        )
    }

    func invalidate(owner: String) throws {
        let url = url(for: owner)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func url(for owner: String) -> URL {
        container.appendingPathComponent(
            "\(Constants.prefix)\(owner)"
        )
    }

    var dbs: [Descriptor] {
        get throws {
            let contents = try FileManager.default.contentsOfDirectory(
                at: container,
                includingPropertiesForKeys: nil
            )
            return contents.compactMap { url in
                let filename = url.lastPathComponent
                guard filename.hasPrefix(Constants.prefix) else {
                    return nil
                }
                guard filename.count > Constants.prefix.count else {
                    return nil
                }
                let owner = filename
                    .suffix(filename.count - Constants.prefix.count)
                return Descriptor(
                    owner: String(owner),
                    container: url
                )
            }
        }
    }
}
