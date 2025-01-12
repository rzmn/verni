import Foundation
import Logging
import Filesystem
internal import SQLite
internal import Convenience

@StorageActor final class SqliteDbPathManager: Sendable {
    let logger: Logger

    private let pathManager: Filesystem.FileManager
    private let versionLabel: String
    private let containerDirectory: URL

    init(
        logger: Logger,
        containerDirectory: URL,
        versionLabel: String,
        pathManager: Filesystem.FileManager
    ) throws {
        self.logger = logger
        self.versionLabel = versionLabel
        self.containerDirectory = containerDirectory.appending(path: "sqlite_\(versionLabel)")
        self.pathManager = pathManager
        do {
            try pathManager.createDirectory(at: self.containerDirectory)
        } catch {
            logE { "failed to create db path manager, error: \(error)" }
            throw error
        }
        logI { "created [version=\(versionLabel)] at \(containerDirectory)" }
    }
}

extension SqliteDbPathManager: DbPathManager {
    struct Item: Sendable {
        let id: String
        private let databaseDirectory: URL

        init(id: String, databaseDirectory: URL) {
            self.id = id
            self.databaseDirectory = databaseDirectory
        }

        func connection() throws -> Connection {
            try Connection(
                databaseDirectory
                    .appending(path: "db.sqlite")
                    .absoluteString
            )
        }
    }

    func create(id: String) throws -> Item {
        invalidateIfNeeded()
        let directory = databaseDirectory(for: id)
        do {
            let created = try pathManager.createDirectory(at: directory)
            guard created else {
                throw InternalError.error("database already exists", underlying: nil)
            }
        } catch {
            logE { "failed to create directory for id \(id), error: \(error)" }
            throw error
        }
        return Item(
            id: id,
            databaseDirectory: directory
        )
    }

    func invalidate(id: String) {
        logI { "id \(id) has been marked as in need of invalidation" }
        idsToInvalidate = modify(idsToInvalidate) {
            $0.insert(id)
        }
    }

    var items: [Item] {
        get throws {
            invalidateIfNeeded()
            let idsToSkip = idsToInvalidate
            return try pathManager
                .listDirectory(at: containerDirectory, mask: .directory)
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
                    return Item(
                        id: id,
                        databaseDirectory: url
                    )
                }
        }
    }
}

extension SqliteDbPathManager: Loggable {}

// MARK: - Private

extension SqliteDbPathManager {
    private var idsToInvalidateKey: String {
        "db_ids_to_invalidate_\(versionLabel)"
    }

    private var userDefaults: UserDefaults {
        .standard
    }

    private var idsToInvalidate: Set<String> {
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

    private var databaseDirectoryPrefix: String {
        "id_"
    }

    private func databaseDirectory(for id: String) -> URL {
        containerDirectory.appendingPathComponent(
            "\(databaseDirectoryPrefix)\(id)"
        )
    }

    private func invalidateIfNeeded() {
        logD { "invalidating deferred dbs" }
        idsToInvalidate = idsToInvalidate
            .filter { item in
                do {
                    try pathManager.removeItem(at: databaseDirectory(for: item))
                    logI { "invalidated db for id \(item)" }
                    return false
                } catch {
                    logE { "failed to invalidate db with id \(item), error: \(error)" }
                    return true
                }
            }
    }
}
