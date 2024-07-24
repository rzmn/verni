import Foundation
import Api
import PersistentStorage
import ApiService

public class ActiveSession: TokenRefresher {
    public var api: Api!
    private let anonymousApi: Api

    public private(set) var persistency: Persistency
    public private(set) var accessToken: String?

    public static func awake(
        anonymousApi: Api,
        hostId: String,
        accessToken: String?,
        refreshToken: String,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory
    ) async throws -> ActiveSession {
        let persistency = try persistencyFactory.create(hostId: hostId, refreshToken: refreshToken)
        return ActiveSession(
            anonymousApi: anonymousApi,
            persistency: persistency,
            accessToken: accessToken,
            apiServiceFactory: apiServiceFactory
        )
    }

    public static func awake(
        anonymousApi: Api,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory
    ) async -> ActiveSession? {
        guard let persistency = persistencyFactory.awake() else {
            return nil
        }
        return ActiveSession(
            anonymousApi: anonymousApi,
            persistency: persistency,
            accessToken: nil,
            apiServiceFactory: apiServiceFactory
        )
    }

    init(anonymousApi: Api, persistency: Persistency, accessToken: String?, apiServiceFactory: ApiServiceFactory) {
        self.persistency = persistency
        self.accessToken = accessToken
        self.anonymousApi = anonymousApi
        self.api = Api(service: apiServiceFactory.create(tokenRefresher: self), polling: TimerBasedPolling())
    }

    public func refreshTokens() async -> Result<Void, RefreshTokenFailureReason> {
        switch await anonymousApi.refresh(token: await persistency.getRefreshToken()) {
        case .success(let tokens):
            accessToken = tokens.accessToken
            await persistency.update(refreshToken: tokens.refreshToken)
            return .success(())
        case .failure(let reason):
            switch reason {
            case .api(let apiErrorCode, _):
                invalidate()
                switch apiErrorCode {
                case .tokenExpired:
                    return .failure(.expired(reason))
                default:
                    return .failure(.internalError(reason))
                }
            case .noConnection(let error):
                return .failure(.noConnection(error))
            case .internalError(let error):
                invalidate()
                return .failure(.internalError(error))
            }
        }
    }

    public func invalidate() {
        Task.detached {
            await self.persistency.invalidate()
        }
    }
}
