import Foundation
import ApiService
import PersistentStorage
import Api
private import DataTransferObjects

actor RefreshTokenManager {
    private let api: ApiProtocol
    private let persistency: Persistency
    private var accessTokenValue: String?

    private let onRefreshTokenExpiredOnInvalid: () -> Void

    init(api: ApiProtocol, persistency: Persistency, onRefreshTokenExpiredOnInvalid: @escaping () -> Void) {
        self.api = api
        self.persistency = persistency
        self.onRefreshTokenExpiredOnInvalid = onRefreshTokenExpiredOnInvalid
    }
}

extension RefreshTokenManager: TokenRefresher {
    func accessToken() async -> String? {
        accessTokenValue
    }

    func refreshTokens() async throws(RefreshTokenFailureReason) {
        let response: AuthTokenDto
        do {
            response = try await api.run(
                method: Auth.Refresh(
                    refreshToken: await persistency.getRefreshToken()
                )
            )
        } catch {
            switch error {
            case .api(let apiErrorCode, _):
                onRefreshTokenExpiredOnInvalid()
                switch apiErrorCode {
                case .tokenExpired:
                    throw .expired(error)
                default:
                    throw .internalError(error)
                }
            case .noConnection(let error):
                throw .noConnection(error)
            case .internalError(let error):
                onRefreshTokenExpiredOnInvalid()
                throw .internalError(error)
            }
        }
        accessTokenValue = response.accessToken
        await persistency.update(refreshToken: response.refreshToken)
    }
}
