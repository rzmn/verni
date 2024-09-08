import Foundation

public struct AuthTokenDto: Decodable, Sendable {
    public let id: UserDto.ID
    public let accessToken: String
    public let refreshToken: String
}
