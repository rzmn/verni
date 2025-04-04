import DataLayer
import InfrastructureLayer
import PersistentStorage
import Logging
import Foundation
import AsyncExtensions
import Api
internal import LoggingExtensions
internal import Convenience
internal import DefaultApiImplementation
internal import RemoteSyncEngine
internal import PersistentStorageSQLite
internal import DefaultServerSideEvents

public final class DefaultDataLayer: Sendable {
    public let logger: Logger
    public let sandbox: DataSession
    public let userDefaults: AsyncExtensions.Atomic<UserDefaults>
    
    private let apiEndpoint: URL
    private let storageFactory: StorageFactory
    private let infrastructure: InfrastructureLayer
    
    public init(
        infrastructure: InfrastructureLayer,
        dataVersionLabel: String,
        appGroupId: String,
        apiEndpoint: URL
    ) throws {
        guard let permanentCacheDirectory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            throw InternalError.error("cannot get required directories for data storage", underlying: nil)
        }
        self.apiEndpoint = apiEndpoint
        self.infrastructure = infrastructure
        self.logger = infrastructure.logger
            .with(scope: .dataLayer(.shared))
        let appGroupDefaults = UserDefaults(suiteName: appGroupId)
        userDefaults = .init(
            value: appGroupDefaults ?? .standard
        )
        storageFactory = try SQLiteStorageFactory(
            logger: infrastructure.logger.with(
                scope: .database
            ),
            dbDirectory: permanentCacheDirectory,
            taskFactory: infrastructure.taskFactory,
            userDefaults: userDefaults,
            dataVersionLabel: dataVersionLabel,
            fileManager: infrastructure.fileManager
        )
        sandbox = SandboxDataSession(
            storageFactory: storageFactory,
            infrastructure: infrastructure,
            apiEndpoint: apiEndpoint
        )

    }
}

extension DefaultDataLayer: DataLayer {
    struct Preview: DataLayerPreview {
        var hostId: HostId {
            storagePreview.hostId
        }
        private let storagePreview: UserStoragePreview
        private let sandboxSession: DataSession
        private let taskFactory: TaskFactory
        private let apiEndpoint: URL
        private let logger: Logger
        
        init(
            storagePreview: UserStoragePreview,
            sandboxSession: DataSession,
            taskFactory: TaskFactory,
            apiEndpoint: URL,
            logger: Logger
        ) {
            self.storagePreview = storagePreview
            self.sandboxSession = sandboxSession
            self.taskFactory = taskFactory
            self.logger = logger
            self.apiEndpoint = apiEndpoint
        }
        
        func awake(loggedOutHandler: EventPublisher<Void>) async throws -> (DataSession, UserStorage) {
            let storage = try await storagePreview.awake()
            let refreshTokenRepository = RefreshTokenManager(
                api: sandboxSession.api,
                persistency: storage,
                authenticationLostSubject: loggedOutHandler,
                accessToken: nil as String?
            )
            let apiFactory = DefaultApiFactory(
                url: apiEndpoint,
                taskFactory: taskFactory,
                logger: logger
                    .with(scope: .api),
                serverSideEventsFactory: DefaultServerSideEventsServiceFactory(
                    taskFactory: taskFactory,
                    logger: logger.with(
                        prefix: "[sse]"
                    ),
                    endpoint: apiEndpoint
                ),
                tokenRepository: refreshTokenRepository
            )
            let api = apiFactory.create()
            let syncFactory = RemoteSyncEngineFactory(
                api: api,
                updates: apiFactory.remoteUpdates(),
                storage: storage,
                taskFactory: taskFactory,
                logger: logger
                    .with(scope: .sync)
            )
            return (
                HostedDataSession(
                    api: api,
                    sync: await syncFactory.create()
                ),
                storage
            )
        }
    }
    
    public var available: [DataLayerPreview] {
        get async {
            do {
                return try await storageFactory.hostsAvailable
                    .map {
                        Preview(
                            storagePreview: $0,
                            sandboxSession: sandbox,
                            taskFactory: infrastructure.taskFactory,
                            apiEndpoint: apiEndpoint,
                            logger: infrastructure.logger
                                .with(scope: .dataLayer(.hosted))
                        )
                    }
            } catch {
                logE { "failed to get available hosts error: \(error)" }
                return []
            }
        }
    }
    
    public func create(
        startupData: Components.Schemas.StartupData,
        deviceId: String,
        loggedOutHandler: EventPublisher<Void>
    ) async throws -> (DataSession, UserStorage) {
        let logger = infrastructure.logger
            .with(scope: .dataLayer(.hosted))
        let storage: UserStorage
        if let existing = try await storageFactory.hostsAvailable.first(where: { $0.hostId == startupData.session.id }) {
            logI { "existed session found, awaking" }
            storage = try await existing.awake()
            try await storage.update(refreshToken: startupData.session.refreshToken)
            try await storage.update(
                operations: startupData.operations.map{
                    Operation(kind: .pendingConfirm, payload: $0)
                }
            )
        } else {
            logI { "no existed session found, creating" }
            storage = try await storageFactory.create(
                host: startupData.session.id,
                deviceId: deviceId,
                refreshToken: startupData.session.refreshToken,
                operations: startupData.operations.map {
                    Operation(kind: .pendingConfirm, payload: $0)
                }
            )
        }
        let refreshTokenRepository = RefreshTokenManager(
            api: sandbox.api,
            persistency: storage,
            authenticationLostSubject: loggedOutHandler,
            accessToken: nil as String?
        )
        let apiFactory = DefaultApiFactory(
            url: apiEndpoint,
            taskFactory: infrastructure.taskFactory,
            logger: logger
                .with(scope: .api),
            serverSideEventsFactory: DefaultServerSideEventsServiceFactory(
                taskFactory: infrastructure.taskFactory,
                logger: logger.with(
                    prefix: "[sse]"
                ),
                endpoint: apiEndpoint
            ),
            tokenRepository: refreshTokenRepository
        )
        let api = apiFactory.create()
        let syncFactory = RemoteSyncEngineFactory(
            api: api,
            updates: apiFactory.remoteUpdates(),
            storage: storage,
            taskFactory: infrastructure.taskFactory,
            logger: logger
                .with(scope: .sync)
        )
        return (
            HostedDataSession(
                api: api,
                sync: await syncFactory.create()
            ),
            storage
        )
    }
    
    public func deleteSession(hostId: HostId) async {
        let session: UserStorage
        do {
            let preview = try await storageFactory.hostsAvailable.first(where: { $0.hostId == hostId })
            guard let preview else {
                return logW { "session with host \(hostId) not found" }
            }
            session = try await preview.awake()
        } catch {
            return logE { "failed awake hosted storage error: \(error)" }
        }
        await session.invalidate()
    }
}

extension DefaultDataLayer: Loggable {}
