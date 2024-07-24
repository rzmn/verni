import Foundation

public enum RefreshTokenFailureReason: Error {
    case noConnection(Error)
    case expired(Error)
    case internalError(Error)
}

public protocol TokenRefresher {
    var accessToken: String? { get }
    func refreshTokens() async -> Result<Void, RefreshTokenFailureReason>
}
