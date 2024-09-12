import Domain
import Foundation
import Base
import Logging

public actor DefaultAvatarsOfflineRepository {
    public let logger: Logger
    private let container: URL

    private enum Constants {
        static let containerDirName = "avatars"
        static let prefix = "s_v1_"
    }

    public init(container _container: URL, logger: Logger) throws {
        self.container = _container.appendingPathComponent(Constants.containerDirName)
        self.logger = logger
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

    private func name(for id: Avatar.ID) -> String {
        "\(Constants.prefix)\(id)"
    }
}

extension DefaultAvatarsOfflineRepository: AvatarsOfflineRepository {
    public func get(for id: Avatar.ID) async -> Data? {
        let id = name(for: id)
        do {
            return try Data(contentsOf: container.appending(component: id))
        } catch {
            logE { "failed to get data with id \(id), error: \(error)" }
            return nil
        }
    }
}

extension DefaultAvatarsOfflineRepository: AvatarsOfflineMutableRepository {
    public func store(data: Data, for id: Avatar.ID) async {
        let id = name(for: id)
        guard FileManager.default.createFile(
            atPath: container.appending(component: id).path,
            contents: data
        ) else {
            return logE { "failed to write data for id \(id)" }
        }
    }
}

extension DefaultAvatarsOfflineRepository: Loggable {}
