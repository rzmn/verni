import Api
import PersistentStorage
import DataLayer
import AsyncExtensions
import Logging
internal import RemoteSyncEngine
internal import DefaultApiImplementation
internal import Convenience

final class DefaultAuthenticatedSessionFactory {
    private let logger: Logger
    private let persistencyFactory: StorageFactory
    private let sessionHost: SessionHost
    private let taskFactory: TaskFactory
    private let api: APIProtocol

    init(
        api: APIProtocol,
        taskFactory: TaskFactory,
        logger: Logger,
        persistencyFactory: StorageFactory
    ) {
        self.api = api
        self.taskFactory = taskFactory
        self.logger = logger
        self.persistencyFactory = persistencyFactory
        self.sessionHost = SessionHost()
    }
}

extension DefaultAuthenticatedSessionFactory: AuthenticatedDataLayerSessionFactory {
    func awakeAuthorizedSession() async throws(DataLayerAwakeError) -> AuthenticatedDataLayerSession {
        guard let host = await sessionHost.active else {
            throw .hasNoSession
        }
        guard let persistency = await persistencyFactory.awake(host: host) else {
            assertionFailure()
            throw .internalError(
                InternalError.error(
                    "session host's session is expired or broken",
                    underlying: nil
                )
            )
        }
        return await buildSession(persistency: persistency, accessToken: nil)
    }

    func createAuthorizedSession(
        session token: Components.Schemas.Session,
        operations: [Components.Schemas.Operation]
    ) async throws -> AuthenticatedDataLayerSession {
        let persistency = try await persistencyFactory.create(
            host: token.id,
            refreshToken: token.refreshToken,
            operations: operations.map {
                Operation(kind: .pendingConfirm, payload: $0)
            }
        )
        await sessionHost.sessionStarted(host: token.id)
        return await buildSession(persistency: persistency, accessToken: token.accessToken)
    }

    private func buildSession(
        persistency: UserStorage,
        accessToken: String?
    ) async -> AuthenticatedDataLayerSession {
        let authenticationLostSubject = AsyncSubject<Void>(
            taskFactory: taskFactory,
            logger: logger
        )
        let tokenRefresher = RefreshTokenManager(
            api: api,
            persistency: persistency,
            authenticationLostSubject: authenticationLostSubject,
            accessToken: accessToken
        )
        let apiFactory = DefaultApiFactory(
            url: Constants.apiEndpoint,
            taskFactory: taskFactory,
            logger: logger,
            tokenRepository: tokenRefresher
        )
        let api = apiFactory.create()
        return DefaultAuthenticatedSession(
            api: api,
            storage: persistency,
            sync: await RemoteSyncEngineFactory(
                api: api,
                storage: persistency,
                taskFactory: taskFactory,
                logger: logger
                    .with(prefix: "🔄")
            ).create(),
            authenticationLostHandler: authenticationLostSubject,
            sessionHost: sessionHost
        )
    }
}
