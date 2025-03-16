import Foundation
import Logging
import Filesystem
import PersistentStorage
internal import SQLite
internal import Convenience

@StorageActor struct SqliteUserStorageManager: Sendable {
    let logger: Logger

    private let environment: Environment
    private let idsToInvalidate: IdsHolder

    nonisolated init(logger: Logger, environment: Environment) throws {
        self.logger = logger
        self.environment = environment
        self.idsToInvalidate = IdsHolder(versionLabel: environment.versionLabel)
    }
}

extension SqliteUserStorageManager: UserStorageManager {
    func create(hostId: HostId, deviceId: String, refreshToken: String, operations: [Operation]) async throws -> UserStorage {
        invalidateIfNeeded()
        let directory = databaseDirectory(for: hostId)
        do {
            let created = try environment.fileManager.createDirectory(at: directory)
            guard created else {
                throw InternalError.error("database already exists", underlying: nil)
            }
        } catch {
            logE { "failed to create directory for id \(hostId), error: \(error)" }
            throw error
        }
        let connection = try Connection(
            directory
                .appending(path: "db.sqlite")
                .absoluteString
        )
        do {
            try connection.createTablesForUser()
        } catch {
            invalidator(for: hostId)()
            throw error
        }
        return try await SQLiteUserStorage(
            database: connection,
            invalidator: invalidator(for: hostId),
            hostId: hostId,
            initialData: SQLiteUserStorage.InitialData(
                refreshToken: refreshToken,
                deviceId: deviceId,
                operations: operations
            ),
            logger: logger
        )
    }
    
    func invalidator(for hostId: HostId) -> @StorageActor @Sendable () -> Void {
        return {
            logI { "id \(hostId) has been marked as in need of invalidation" }
            idsToInvalidate.value = modify(idsToInvalidate.value) {
                $0.insert(hostId)
            }
        }
    }

    var items: [UserStoragePreview] {
        get throws {
            invalidateIfNeeded()
            let idsToSkip = idsToInvalidate.value
            return try environment.fileManager
                .listDirectory(at: environment.containerDirectory, mask: .directory)
                .compactMap { url in
                    let directoryName = url.lastPathComponent
                    guard directoryName.starts(with: databaseDirectoryPrefix) else {
                        return nil
                    }
                    let id = String(directoryName.suffix(
                        directoryName.count - databaseDirectoryPrefix.count
                    ))
                    guard !idsToSkip.contains(id) else {
                        return nil
                    }
                    return Item(hostId: id, manager: self, logger: logger)
                }
        }
    }
}

extension SqliteUserStorageManager {
    struct Item: Sendable, UserStoragePreview {
        let hostId: HostId
        let invalidator: @StorageActor @Sendable () -> Void
        let logger: Logger
        private let databaseDirectory: URL

        @StorageActor init(
            hostId: HostId,
            manager: SqliteUserStorageManager,
            logger: Logger
        ) {
            self.hostId = hostId
            self.databaseDirectory = manager.databaseDirectory(for: hostId)
            self.invalidator = manager.invalidator(for: hostId)
            self.logger = logger
        }
        
        @StorageActor func awake() async throws -> any UserStorage {
            return try await SQLiteUserStorage(
                database: try Connection(
                    databaseDirectory
                        .appending(path: "db.sqlite")
                        .absoluteString
                ),
                invalidator: invalidator,
                hostId: hostId,
                initialData: nil,
                logger: logger
            )
        }
    }
}

extension SqliteUserStorageManager: Loggable {}

// MARK: - Private

extension SqliteUserStorageManager {
    final class IdsHolder: Sendable {
        private let versionLabel: String
        
        private var idsToInvalidateKey: String {
            "db_ids_to_invalidate_\(versionLabel)"
        }

        private var userDefaults: UserDefaults {
            .standard
        }
        
        var value: Set<String> {
            get {
                userDefaults
                    .dictionary(forKey: idsToInvalidateKey)
                    .flatMap(\.keys)
                    .map(Set.init)
                    .emptyIfNil
            }
            set {
                userDefaults
                    .set(newValue.reduce(into: [:]) { dict, item in
                        dict[item] = true
                    }, forKey: idsToInvalidateKey)
            }
        }
        
        init(versionLabel: String) {
            self.versionLabel = versionLabel
        }
    }
}

extension SqliteUserStorageManager {
    private var databaseDirectoryPrefix: String {
        "id_"
    }

    private func databaseDirectory(for id: String) -> URL {
        environment.containerDirectory.appendingPathComponent(
            "\(databaseDirectoryPrefix)\(id)"
        )
    }

    private func invalidateIfNeeded() {
        logD { "invalidating deferred dbs" }
        idsToInvalidate.value = idsToInvalidate.value
            .filter { item in
                do {
                    try environment.fileManager.removeItem(at: databaseDirectory(for: item))
                    logI { "invalidated db for id \(item)" }
                    return false
                } catch {
                    logE { "failed to invalidate db with id \(item), error: \(error)" }
                    return true
                }
            }
    }
}
