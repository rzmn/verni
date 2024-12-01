import Foundation
import PersistentStorage
import Api
import AsyncExtensions
import DataTransferObjects
internal import ApiService

actor RefreshTokenManager {
    private let api: ApiProtocol
    private let persistency: Persistency
    private var accessTokenValue: String?
    private let authenticationLostSubject: AsyncSubject<Void>

    init(
        api: ApiProtocol,
        persistency: Persistency,
        authenticationLostSubject: AsyncSubject<Void>,
        accessToken: String?
    ) {
        self.api = api
        self.persistency = persistency
        self.authenticationLostSubject = authenticationLostSubject
        self.accessTokenValue = accessToken
        print("[debug] init with access token: \(accessToken ?? "<nil>")")
    }
}

extension RefreshTokenManager: TokenRefresher {
    func accessToken() async -> String? {
        accessTokenValue
    }

    func refreshTokens() async throws(RefreshTokenFailureReason) {
        let response: AuthTokenDto
        do {
            let token =  await persistency.getRefreshToken()
            print("[debug] refreshing with refresh token: \(token)")
            response = try await api.run(
                method: Auth.Refresh(
                    refreshToken: token
                )
            )
            print("[debug] refresh token: \(response.refreshToken) access token: \(response.accessToken)")
        } catch {
            switch error {
            case .api(let apiErrorCode, _):
                await authenticationLostSubject.yield(())
                switch apiErrorCode {
                case .tokenExpired:
                    throw .expired(error)
                default:
                    throw .internalError(error)
                }
            case .noConnection(let error):
                throw .noConnection(error)
            case .internalError(let error):
                await authenticationLostSubject.yield(())
                throw .internalError(error)
            }
        }
        accessTokenValue = response.accessToken
        await persistency.update(refreshToken: response.refreshToken)
    }
}
