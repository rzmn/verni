import Domain
import Foundation
import Base
import Logging

public actor DefaultAvatarsOfflineRepository {
    public let logger: Logger
    private let storageDir: URL

    private enum Constants {
        static let storageDirName = "avatars"
        static let prefix = "s_v1_"
    }

    public init(container: URL, logger: Logger) throws {
        self.storageDir = container.appendingPathComponent(Constants.storageDirName)
        self.logger = logger
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(
            atPath: storageDir.path,
            isDirectory: &isDirectory
        )
        if !exists {
            try FileManager.default.createDirectory(
                at: storageDir,
                withIntermediateDirectories: true
            )
        } else if !isDirectory.boolValue {
            throw InternalError.error("already has a file at \(storageDir)", underlying: nil)
        }
    }

    nonisolated private func name(for id: Avatar.Identifier) -> String {
        "\(Constants.prefix)\(id)"
    }
}

extension DefaultAvatarsOfflineRepository: AvatarsOfflineRepository {
    nonisolated public func get(for id: Avatar.Identifier) -> Data? {
        let id = name(for: id)
        do {
            return try Data(contentsOf: storageDir.appending(component: id))
        } catch {
            logE { "failed to get data with id \(id), error: \(error)" }
            return nil
        }
    }
}

extension DefaultAvatarsOfflineRepository: AvatarsOfflineMutableRepository {
    public func store(data: Data, for id: Avatar.Identifier) async {
        let id = name(for: id)
        guard FileManager.default.createFile(
            atPath: storageDir.appending(component: id).path,
            contents: data
        ) else {
            return logE { "failed to write data for id \(id)" }
        }
    }
}

extension DefaultAvatarsOfflineRepository: Loggable {}
