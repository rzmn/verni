import Foundation
import Logging
import SwiftData
import DataTransferObjects
import PersistentStorage

public class DefaultPersistencyFactory {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }
}

extension DefaultPersistencyFactory: PersistencyFactory {
    public func awake() -> Persistency? {
        logI { "awaking persistence..." }
        let dbUrl: URL
        do {
            let dbDirectory = DbNameBuilder.shared.dbDirectory
            try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
            let contents = try FileManager.default
                .contentsOfDirectory(at: dbDirectory, includingPropertiesForKeys: nil)
                .filter { $0.isFileURL && DbNameBuilder.shared.isDbName($0.lastPathComponent) }
            if contents.count != 1 {
                logI { "has no persistence" }
                return nil
            }
            dbUrl = contents[0]
        } catch {
            logE { "got error searching for db path error: \(error)" }
            return nil
        }
        guard let hostId = DbNameBuilder.shared.dbOwnerId(dbUrl.lastPathComponent) else {
            logI { "url is not recognized as valid db url \(dbUrl)" }
            return nil
        }
        logI { "found db url: \(dbUrl)" }
        do {
            let modelContainer = try ModelContainer(
                for: PersistentRefreshToken.self, PersistentUser.self,
                configurations: ModelConfiguration(url: dbUrl)
            )
            let context = ModelContext(modelContainer)
            let token = try context.fetch({
                var d = FetchDescriptor<PersistentRefreshToken>()
                d.fetchLimit = 1
                return d
            }()).first
            guard let token else {
                logger.logE { "db does not have host/credentials info" }
                return nil
            }
            return DefaultPersistency(
                modelContext: ModelContext(modelContainer),
                hostId: hostId,
                refreshToken: token,
                logger: logger
            )
        } catch {
            logE { "failed to create db from url due error: \(error)" }
            return nil
        }
    }
    
    public func create(hostId: DataTransferObjects.UserDto.ID, refreshToken: String) throws -> Persistency {
        logI { "creating persistence..." }
        let directoryUrl = DbNameBuilder.shared.dbDirectory
        let modelContainer = try ModelContainer(
            for: PersistentUser.self, PersistentRefreshToken.self,
            configurations: ModelConfiguration(url: directoryUrl.appending(component: DbNameBuilder.shared.dbName(owner: hostId)))
        )
        let refreshToken = PersistentRefreshToken(payload: refreshToken)
        let modelContext = ModelContext(modelContainer)
        modelContext.insert(refreshToken)
        try modelContext.save()
        return DefaultPersistency(
            modelContext: modelContext,
            hostId: hostId,
            refreshToken: refreshToken,
            logger: logger
        )
    }
}

private extension DefaultPersistencyFactory {
    struct DbNameBuilder {
        public static let shared = DbNameBuilder()
        private var prefix: String { "db_" }
        private var suffix: String { ".sqlite" }

        func isDbName(_ filename: String) -> Bool {
            filename.hasPrefix(prefix) && filename.hasSuffix(suffix) && filename != prefix
        }

        func dbOwnerId(_ filename: String) -> String? {
            guard isDbName(filename) else {
                return nil
            }
            return String(filename.suffix(filename.count - prefix.count).prefix(filename.count - prefix.count - suffix.count))
        }

        func dbName(owner: String) -> String {
            "\(prefix)\(owner)\(suffix)"
        }

        var dbDirectory: URL {
            URL.documentsDirectory.appending(component: "accounty_db")
        }
    }
}

extension DefaultPersistencyFactory: Loggable {}
