import Foundation
import Logging
internal import Base
internal import SQLite

@StorageActor final class SqliteDbPathManager: Sendable {
    let logger: Logger
    
    private let pathManager: PathManager
    private let versionLabel: String
    private let containerDirectory: URL
    
    init(
        logger: Logger,
        containerDirectory: URL,
        versionLabel: String,
        pathManager: PathManager
    ) throws {
        self.logger = logger
        self.versionLabel = versionLabel
        self.containerDirectory = containerDirectory.appending(path: "sqlite_\(versionLabel)")
        self.pathManager = pathManager
        try pathManager.createDirectory(at: self.containerDirectory)
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
        try pathManager.createDirectory(at: directory)
        return Item(
            id: id,
            databaseDirectory: directory
        )
    }
    
    func invalidate(id: String) {
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
        "ids_to_invalidate"
    }
    
    private var idsToInvalidate: Set<String> {
        get {
            UserDefaults.standard
                .dictionary(forKey: idsToInvalidateKey)
                .flatMap(\.keys)
                .map(Set.init)
            ?? Set()
        }
        set {
            UserDefaults.standard
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
        idsToInvalidate = idsToInvalidate
            .filter { item in
                do {
                    try pathManager.removeItem(at: databaseDirectory(for: item))
                    return false
                } catch {
                    logE { "failed to invalidate db with id \(item), error: \(error)" }
                    return true
                }
            }
    }
}
