import Foundation
import Api
import DI
import PersistentStorage
import ApiService
import Domain
@preconcurrency import Combine
internal import Base

public protocol ActiveSessionDIContainerFactory: Sendable {
    func create(
        api: ApiProtocol,
        persistency: Persistency,
        longPoll: LongPoll,
        logoutSubject: PassthroughSubject<LogoutReason, Never>,
        userId: User.ID
    ) async -> ActiveSessionDIContainer
}

public actor ActiveSession: ActiveSessionDIContainerConvertible {
    private var _activeSessionDIContainer: (any ActiveSessionDIContainer)?
    public func activeSessionDIContainer() async -> any ActiveSessionDIContainer {
        guard let _activeSessionDIContainer else {
            let container = await factory.create(
                api: authenticatedApiFactory.create(),
                persistency: persistency,
                longPoll: authenticatedApiFactory.longPoll(),
                logoutSubject: logoutSubject,
                userId: userId
            )
            _activeSessionDIContainer = container
            return container
        }
        return _activeSessionDIContainer
    }
    private let authenticatedApiFactory: ApiFactory
    private let apiFactoryProvider: @Sendable (TokenRefresher) async -> ApiFactory
    private let anonymousApi: ApiProtocol
    private let factory: ActiveSessionDIContainerFactory
    private let logoutSubject = PassthroughSubject<LogoutReason, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private let tokenRefresher: TokenRefresher
    private let userId: User.ID
    private let persistency: Persistency
    private let accessToken: String?

    public static func create(
        anonymousApi: ApiProtocol,
        hostId: User.ID,
        accessToken: String?,
        refreshToken: String,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory,
        activeSessionDIContainerFactory: ActiveSessionDIContainerFactory,
        apiFactoryProvider: @escaping @Sendable (TokenRefresher) async -> ApiFactory
    ) async throws -> ActiveSession {
        let persistency = try await persistencyFactory.create(host: hostId, refreshToken: refreshToken)
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
        apiFactoryProvider: @escaping @Sendable (TokenRefresher) async -> ApiFactory
    ) async -> ActiveSession? {
        guard let host = await SessionHost().active else {
            return nil
        }
        guard let persistency = await persistencyFactory.awake(host: host) else {
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
        apiFactoryProvider: @escaping @Sendable (TokenRefresher) async -> ApiFactory
    ) async {
        self.persistency = persistency
        self.accessToken = accessToken
        self.anonymousApi = anonymousApi
        self.apiFactoryProvider = apiFactoryProvider
        self.factory = activeSessionDIContainerFactory
        self.userId = await persistency.userId()
        tokenRefresher = RefreshTokenManager(
            api: anonymousApi,
            persistency: persistency,
            onRefreshTokenExpiredOnInvalid: curry(weak(logoutSubject, type(of: logoutSubject).send))(.refreshTokenFailed)
        )
        self.authenticatedApiFactory = await apiFactoryProvider(tokenRefresher)
        let sessionHost = SessionHost()
        await sessionHost.sessionStarted(host: self.userId)
        logoutSubject.sink { reason in
            Task {
                await sessionHost.sessionFinished()
            }
        }.store(in: &subscriptions)
    }
}
