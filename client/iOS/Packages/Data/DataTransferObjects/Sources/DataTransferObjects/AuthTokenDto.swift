import Foundation

public struct AuthTokenDto: Decodable {
    public let id: UserDto.ID
    public let accessToken: String
    public let refreshToken: String
}
