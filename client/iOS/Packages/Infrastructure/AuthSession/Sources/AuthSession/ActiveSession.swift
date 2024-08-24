import Foundation
import Api
import DI
import PersistentStorage
import ApiService
import Domain
import Combine
internal import Base

public protocol ActiveSessionDIContainerFactory {
    func create(
        api: ApiProtocol,
        persistency: Persistency,
        longPoll: LongPoll,
        logoutSubject: PassthroughSubject<LogoutReason, Never>,
        userId: User.ID
    ) -> ActiveSessionDIContainer
}

public class ActiveSession: ActiveSessionDIContainerConvertible {
    public lazy var activeSessionDIContainer = factory.create(
        api: authenticatedApiFactory.create(),
        persistency: persistency,
        longPoll: authenticatedApiFactory.longPoll(), 
        logoutSubject: logoutSubject,
        userId: userId
    )
    private lazy var authenticatedApiFactory = apiFactoryProvider(tokenRefresher)
    private let apiFactoryProvider: (TokenRefresher) -> ApiFactory
    private let anonymousApi: ApiProtocol
    private let factory: ActiveSessionDIContainerFactory
    private let logoutSubject = PassthroughSubject<LogoutReason, Never>()

    private lazy var tokenRefresher: TokenRefresher = RefreshTokenManager(
        api: anonymousApi,
        persistency: persistency, 
        onSessionInvalidated: curry(weak(logoutSubject, type(of: logoutSubject).send))(.refreshTokenFailed)
    )
    private let userId: User.ID
    private let persistency: Persistency
    private let accessToken: String?

    public static func awake(
        anonymousApi: ApiProtocol,
        hostId: User.ID,
        accessToken: String?,
        refreshToken: String,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory,
        activeSessionDIContainerFactory: ActiveSessionDIContainerFactory,
        apiFactoryProvider: @escaping (TokenRefresher) -> ApiFactory
    ) async throws -> ActiveSession {
        let persistency = try persistencyFactory.create(hostId: hostId, refreshToken: refreshToken)
        return await ActiveSession(
            anonymousApi: anonymousApi,
            persistency: persistency, 
            activeSessionDIContainerFactory: activeSessionDIContainerFactory,
            accessToken: accessToken,
            apiFactoryProvider: apiFactoryProvider
        )
    }

    public static func awake(
        anonymousApi: ApiProtocol,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory,
        activeSessionDIContainerFactory: ActiveSessionDIContainerFactory,
        apiFactoryProvider: @escaping (TokenRefresher) -> ApiFactory
    ) async -> ActiveSession? {
        guard let persistency = persistencyFactory.awake() else {
            return nil
        }
        return await ActiveSession(
            anonymousApi: anonymousApi,
            persistency: persistency, 
            activeSessionDIContainerFactory: activeSessionDIContainerFactory,
            accessToken: nil,
            apiFactoryProvider: apiFactoryProvider
        )
    }

    private init(
        anonymousApi: ApiProtocol,
        persistency: Persistency,
        activeSessionDIContainerFactory: ActiveSessionDIContainerFactory,
        accessToken: String?,
        apiFactoryProvider: @escaping (TokenRefresher) -> ApiFactory
    ) async {
        self.persistency = persistency
        self.accessToken = accessToken
        self.anonymousApi = anonymousApi
        self.apiFactoryProvider = apiFactoryProvider
        self.factory = activeSessionDIContainerFactory
        self.userId = await persistency.userId()
    }
}
