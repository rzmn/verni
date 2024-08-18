import Foundation

public enum RefreshTokenFailureReason: Error {
    case noConnection(Error)
    case expired(Error)
    case internalError(Error)
}

public protocol TokenRefresher {
    func accessToken() async -> String?
    func refreshTokens() async -> Result<Void, RefreshTokenFailureReason>
}
