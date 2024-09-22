import Foundation

public struct AuthTokenDto: Decodable, Sendable {
    public let id: UserDto.Identifier
    public let accessToken: String
    public let refreshToken: String
}
