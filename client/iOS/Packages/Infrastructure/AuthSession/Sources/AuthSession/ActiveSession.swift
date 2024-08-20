import Foundation
import Api
import DI
import PersistentStorage
import ApiService
import Domain

public class ActiveSession {
    public lazy var api = apiFactoryProvider(tokenRefresher).create()
    public lazy var longPoll = apiFactoryProvider(tokenRefresher).longPoll()
    private let apiFactoryProvider: (TokenRefresher) -> ApiFactory
    private let anonymousApi: ApiProtocol

    private lazy var tokenRefresher: TokenRefresher = RefreshTokenManager(
        api: anonymousApi,
        persistency: persistency, 
        onSessionInvalidated: invalidate
    )
    public let appCommon: AppCommon
    public let userId: User.ID
    public private(set) var persistency: Persistency
    public private(set) var accessToken: String?

    public static func awake(
        anonymousApi: ApiProtocol,
        hostId: User.ID,
        accessToken: String?,
        refreshToken: String,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory,
        appCommon: AppCommon,
        apiFactoryProvider: @escaping (TokenRefresher) -> ApiFactory
    ) async throws -> ActiveSession {
        let persistency = try persistencyFactory.create(hostId: hostId, refreshToken: refreshToken)
        return await ActiveSession(
            anonymousApi: anonymousApi,
            persistency: persistency, 
            appCommon: appCommon,
            accessToken: accessToken,
            apiFactoryProvider: apiFactoryProvider
        )
    }

    public static func awake(
        anonymousApi: ApiProtocol,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory,
        appCommon: AppCommon,
        apiFactoryProvider: @escaping (TokenRefresher) -> ApiFactory
    ) async -> ActiveSession? {
        guard let persistency = persistencyFactory.awake() else {
            return nil
        }
        return await ActiveSession(
            anonymousApi: anonymousApi,
            persistency: persistency, 
            appCommon: appCommon,
            accessToken: nil,
            apiFactoryProvider: apiFactoryProvider
        )
    }

    private init(
        anonymousApi: ApiProtocol,
        persistency: Persistency,
        appCommon: AppCommon,
        accessToken: String?,
        apiFactoryProvider: @escaping (TokenRefresher) -> ApiFactory
    ) async {
        self.persistency = persistency
        self.accessToken = accessToken
        self.anonymousApi = anonymousApi
        self.apiFactoryProvider = apiFactoryProvider
        self.appCommon = appCommon
        self.userId = await persistency.userId()
    }

    public func invalidate() {
        Task.detached {
            await self.persistency.invalidate()
        }
    }
}
