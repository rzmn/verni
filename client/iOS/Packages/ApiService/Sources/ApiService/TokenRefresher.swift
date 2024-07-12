import Foundation

public protocol TokenRefresher {
    var accessToken: String { get }
    func refreshTokens() async -> Bool
}
