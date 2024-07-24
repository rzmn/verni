import Foundation

public struct AuthTokenDto: Decodable {
    public let accessToken: String
    public let refreshToken: String
}
