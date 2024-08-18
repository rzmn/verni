import Foundation
import ApiService
import PersistentStorage
import Api

actor RefreshTokenManager {
    private var refreshTask: Task<Result<Void, RefreshTokenFailureReason>, Never>?
    private let api: ApiProtocol
    private let persistency: Persistency
    private var accessTokenValue: String?
    private let onSessionInvalidated: () -> Void

    init(api: ApiProtocol, persistency: Persistency, onSessionInvalidated: @escaping () -> Void) {
        self.api = api
        self.persistency = persistency
        self.onSessionInvalidated = onSessionInvalidated
    }
}

extension RefreshTokenManager: TokenRefresher {
    func accessToken() async -> String? {
        accessTokenValue
    }

    func refreshTokens() async -> Result<Void, RefreshTokenFailureReason> {
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
        let response = await api.run(
            method: Auth.Refresh(
                refreshToken: await persistency.getRefreshToken()
            )
        )
        switch response {
        case .success(let tokens):
            accessTokenValue = tokens.accessToken
            await persistency.update(refreshToken: tokens.refreshToken)
            return .success(())
        case .failure(let reason):
            switch reason {
            case .api(let apiErrorCode, _):
                onSessionInvalidated()
                switch apiErrorCode {
                case .tokenExpired:
                    return .failure(.expired(reason))
                default:
                    return .failure(.internalError(reason))
                }
            case .noConnection(let error):
                return .failure(.noConnection(error))
            case .internalError(let error):
                onSessionInvalidated()
                return .failure(.internalError(error))
            }
        }
    }
}
