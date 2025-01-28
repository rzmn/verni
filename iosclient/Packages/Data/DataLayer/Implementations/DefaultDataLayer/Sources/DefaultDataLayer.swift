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

public final class DefaultDataLayer: Sendable {
    public let logger: Logger
    public let sandbox: DataSession
    
    private let storageFactory: StorageFactory
    private let infrastructure: InfrastructureLayer
    
    public init(infrastructure: InfrastructureLayer) throws {
        guard let permanentCacheDirectory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroup
        ) else {
            throw InternalError.error("cannot get required directories for data storage", underlying: nil)
        }
        self.infrastructure = infrastructure
        self.logger = infrastructure.logger
            .with(scope: .dataLayer(.shared))
        storageFactory = try SQLiteStorageFactory(
            logger: infrastructure.logger.with(
                scope: .database
            ),
            dbDirectory: permanentCacheDirectory,
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )
        sandbox = SandboxDataSession(
            storageFactory: storageFactory,
            infrastructure: infrastructure
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
        private let logger: Logger
        
        init(
            storagePreview: UserStoragePreview,
            sandboxSession: DataSession,
            taskFactory: TaskFactory,
            logger: Logger
        ) {
            self.storagePreview = storagePreview
            self.sandboxSession = sandboxSession
            self.taskFactory = taskFactory
            self.logger = logger
        }
        
        func awake(loggedOutHandler: AsyncSubject<Void>) async throws -> DataSession {
            let storage = try await storagePreview.awake()
            let apiFactory = DefaultApiFactory(
                url: Constants.apiEndpoint,
                taskFactory: taskFactory,
                logger: logger
                    .with(scope: .api),
                tokenRepository: RefreshTokenManager(
                    api: sandboxSession.api,
                    persistency: storage,
                    authenticationLostSubject: loggedOutHandler,
                    accessToken: nil as String?
                )
            )
            let api = apiFactory.create()
            let syncFactory = RemoteSyncEngineFactory(
                api: api,
                storage: storage,
                taskFactory: taskFactory,
                logger: logger
                    .with(scope: .sync)
            )
            return HostedDataSession(
                api: api,
                sync: await syncFactory.create()
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
        loggedOutHandler: AsyncSubject<Void>
    ) async throws -> DataSession {
        let logger = infrastructure.logger
            .with(scope: .dataLayer(.hosted))
        let storage = try await storageFactory.create(
            host: startupData.session.id,
            refreshToken: startupData.session.refreshToken,
            operations: startupData.operations.map {
                Operation(kind: .pendingConfirm, payload: $0)
            }
        )
        let apiFactory = DefaultApiFactory(
            url: Constants.apiEndpoint,
            taskFactory: infrastructure.taskFactory,
            logger: logger
                .with(scope: .api),
            tokenRepository: RefreshTokenManager(
                api: sandbox.api,
                persistency: storage,
                authenticationLostSubject: loggedOutHandler,
                accessToken: nil as String?
            )
        )
        let api = apiFactory.create()
        let syncFactory = RemoteSyncEngineFactory(
            api: api,
            storage: storage,
            taskFactory: infrastructure.taskFactory,
            logger: logger
                .with(scope: .sync)
        )
        return HostedDataSession(
            api: api,
            sync: await syncFactory.create()
        )
    }
    
    public func deleteSession(hostId: HostId) async {
        assertionFailure("not implemented")
    }
}

extension DefaultDataLayer: Loggable {}
