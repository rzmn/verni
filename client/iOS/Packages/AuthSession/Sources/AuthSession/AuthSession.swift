import Foundation
import Api
import ApiService
import Domain

private let refreshTokenKey: String = "refreshToken"
public class ActiveSession: TokenRefresher {
    public var api: Api!

    public private(set) var refreshToken: String
    public private(set) var accessToken: String

    public static func awake(accessToken: String, refreshToken: String, factory: ApiServiceFactory) async -> ActiveSession {
        UserDefaults.standard.setValue(refreshToken, forKey: refreshTokenKey)
        return ActiveSession(
            refreshToken: refreshToken,
            accessToken: accessToken,
            factory: factory
        )
    }

    public static func awake(anonymousApi: Api, factory: ApiServiceFactory) async -> Result<ActiveSession?, ApiError> {
        let cachedToken = UserDefaults.standard.string(forKey: refreshTokenKey)
        guard let cachedToken else {
            return .success(nil)
        }
        switch await anonymousApi.refresh(token: cachedToken) {
        case .success(let token):
            UserDefaults.standard.setValue(token.refreshToken, forKey: refreshTokenKey)
            return .success(
                ActiveSession(
                    refreshToken: token.refreshToken,
                    accessToken: token.accessToken,
                    factory: factory
                )
            )
        case .failure(let error):
            return .failure(error)
        }
    }

    init(refreshToken: String, accessToken: String, factory: ApiServiceFactory) {
        self.refreshToken = refreshToken
        self.accessToken = accessToken
        self.api = Api(service: factory.create(tokenRefresher: self), polling: TimerBasedPolling())
    }

    public func refreshTokens() async -> Bool {
        switch await api.refresh(token: refreshToken) {
        case .success(let tokens):
            accessToken = tokens.accessToken
            refreshToken = tokens.refreshToken
            return true
        case .failure:
            invalidate()
            return false
        }
    }

    func invalidate() {
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }
}
