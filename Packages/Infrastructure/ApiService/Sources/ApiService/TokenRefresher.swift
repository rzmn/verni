import Foundation

public enum RefreshTokenFailureReason: Error, Sendable {
    case noConnection(Error)
    case expired(Error)
    case internalError(Error)
}

public protocol TokenRefresher: Sendable {
    func accessToken() async -> String?
    func refreshTokens() async throws(RefreshTokenFailureReason)
}
