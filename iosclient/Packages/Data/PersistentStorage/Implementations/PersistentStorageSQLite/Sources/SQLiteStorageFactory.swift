import AsyncExtensions
import Filesystem
import Foundation
import Logging
import PersistentStorage
import Api
internal import SQLite

@StorageActor public final class SQLiteStorageFactory: Sendable {
    public let logger: Logger
    
    private let environment: Environment
    private let userStorageHolder: UserStorageManager
    private let sandboxStorageHolder: SandboxStorageHolder
    private let taskFactory: TaskFactory

    nonisolated public init(
        logger: Logger,
        dbDirectory: URL,
        taskFactory: TaskFactory,
        userDefaults: AsyncExtensions.Atomic<UserDefaults>,
        dataVersionLabel: String,
        fileManager: Filesystem.FileManager
    ) throws {
        self.environment = try Environment(
            logger: logger,
            fileManager: fileManager,
            versionLabel: dataVersionLabel,
            containerDirectory: dbDirectory
        )
        self.logger = logger
        self.taskFactory = taskFactory
        self.sandboxStorageHolder = SandboxStorageHolder(
            logger: logger,
            environment: environment
        )
        self.userStorageHolder = try SqliteUserStorageManager(
            logger: logger,
            userDefaults: userDefaults,
            environment: environment
        )
    }
}

extension SQLiteStorageFactory: StorageFactory {
    public nonisolated var sandbox: SandboxStorage {
        sandboxStorageHolder.storage
    }
    
    public var hostsAvailable: [UserStoragePreview] {
        get async throws {
            try userStorageHolder.items
        }
    }

    public func create(
        host: HostId,
        deviceId: String,
        refreshToken: String,
        operations: [PersistentStorage.Operation]
    ) async throws -> UserStorage {
        try await userStorageHolder.create(
            hostId: host,
            deviceId: deviceId,
            refreshToken: refreshToken,
            operations: operations
        )
    }
}

extension SQLiteStorageFactory: Loggable {}
