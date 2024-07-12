import Foundation
import Api
import ApiService
import Domain

private let refreshTokenKey: String = "refreshToken"
public class ActiveSession: TokenRefresher {
    public var api: Api!
    private let anonymousApi: Api

    public private(set) var refreshToken: String
    public private(set) var accessToken: String?

    public static func awake(anonymousApi: Api, accessToken: String?, refreshToken: String, factory: ApiServiceFactory) async -> ActiveSession {
        UserDefaults.standard.setValue(refreshToken, forKey: refreshTokenKey)
        return ActiveSession(
            anonymousApi: anonymousApi,
            refreshToken: refreshToken,
            accessToken: accessToken,
            factory: factory
        )
    }

    public static func awake(anonymousApi: Api, factory: ApiServiceFactory) async -> ActiveSession? {
        let cachedToken = UserDefaults.standard.string(forKey: refreshTokenKey)
        guard let cachedToken else {
            return nil
        }
        return ActiveSession(
            anonymousApi: anonymousApi,
            refreshToken: cachedToken,
            accessToken: nil,
            factory: factory
        )
    }

    init(anonymousApi: Api, refreshToken: String, accessToken: String?, factory: ApiServiceFactory) {
        UserDefaults.standard.setValue(refreshToken, forKey: refreshTokenKey)
        self.refreshToken = refreshToken
        self.accessToken = accessToken
        self.anonymousApi = anonymousApi
        self.api = Api(service: factory.create(tokenRefresher: self), polling: TimerBasedPolling())
    }

    public func refreshTokens() async -> Result<Void, RefreshTokenFailureReason> {
        switch await anonymousApi.refresh(token: refreshToken) {
        case .success(let tokens):
            UserDefaults.standard.setValue(tokens.refreshToken, forKey: refreshTokenKey)
            accessToken = tokens.accessToken
            refreshToken = tokens.refreshToken
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

    func invalidate() {
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
}
