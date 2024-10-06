import Api
import DataTransferObjects
import PersistentStorage
import DataLayerDependencies
import AsyncExtensions
internal import ApiService
internal import DefaultApiImplementation
internal import Base

final class DefaultAuthenticatedSessionFactory {
    private let persistencyFactory: PersistencyFactory
    private let sessionHost: SessionHost
    private let apiServiceFactory: ApiServiceFactory
    private let taskFactory: TaskFactory
    private let api: ApiProtocol

    init(
        api: ApiProtocol,
        taskFactory: TaskFactory,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory
    ) {
        self.api = api
        self.taskFactory = taskFactory
        self.apiServiceFactory = apiServiceFactory
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
        return await buildSession(persistency: persistency)
    }

    func createAuthorizedSession(
        token: AuthTokenDto
    ) async throws -> AuthenticatedDataLayerSession {
        let persistency = try await persistencyFactory.create(
            host: token.id,
            refreshToken: token.refreshToken
        )
        await sessionHost.sessionStarted(host: token.id)
        return await buildSession(persistency: persistency)
    }

    private func buildSession(
        persistency: Persistency
    ) async -> AuthenticatedDataLayerSession {
        let authenticationLostSubject = AsyncSubject<Void>(taskFactory: taskFactory)
        let tokenRefresher = RefreshTokenManager(
            api: api,
            persistency: persistency,
            authenticationLostSubject: authenticationLostSubject
        )
        let apiService = apiServiceFactory.create(tokenRefresher: tokenRefresher)
        let apiFactory = DefaultApiFactory(
            service: apiService,
            taskFactory: taskFactory
        )
        return DefaultAuthenticatedSession(
            api: apiFactory.create(),
            longPoll: apiFactory.longPoll(),
            persistency: persistency,
            authenticationLostHandler: authenticationLostSubject
        )
    }
}
