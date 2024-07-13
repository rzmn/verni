import Base

public struct ApiAuthTokenDto: Decodable {
    public let accessToken: String
    public let refreshToken: String
}

extension ApiAuthTokenDto: CompactDescription {}
