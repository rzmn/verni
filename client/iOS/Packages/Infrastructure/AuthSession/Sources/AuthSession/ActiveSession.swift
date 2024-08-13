import Foundation
import Api
import DI
import PersistentStorage
import ApiService
import Domain

public class ActiveSession: TokenRefresher {
    public lazy var api = apiFactoryProvider(self).create()
    private let apiFactoryProvider: (TokenRefresher) -> ApiFactory
    private let anonymousApi: ApiProtocol

    public let appCommon: AppCommon
    public private(set) var persistency: Persistency
    public private(set) var accessToken: String?

    public static func awake(
        anonymousApi: ApiProtocol,
        hostId: String,
        accessToken: String?,
        refreshToken: String,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory,
        appCommon: AppCommon,
        apiFactoryProvider: @escaping (TokenRefresher) -> ApiFactory
    ) async throws -> ActiveSession {
        let persistency = try persistencyFactory.create(hostId: hostId, refreshToken: refreshToken)
        return ActiveSession(
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
        return ActiveSession(
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
    ) {
        self.persistency = persistency
        self.accessToken = accessToken
        self.anonymousApi = anonymousApi
        self.apiFactoryProvider = apiFactoryProvider
        self.appCommon = appCommon
    }

    private var refreshTask: Task<Result<Void, RefreshTokenFailureReason>, Never>?
    public func refreshTokens() async -> Result<Void, RefreshTokenFailureReason> {
        if let refreshTask {
            let result = await refreshTask.value
            self.refreshTask = nil
            return result
        } else {
            let task = Task {
                await doRefreshTokens()
            }
            refreshTask = task
            return await task.value
        }
    }

    private func doRefreshTokens() async -> Result<Void, RefreshTokenFailureReason> {
        let response = await anonymousApi.run(
            method: Auth.Refresh(
                refreshToken: await persistency.getRefreshToken()
            )
        )
        switch response {
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
