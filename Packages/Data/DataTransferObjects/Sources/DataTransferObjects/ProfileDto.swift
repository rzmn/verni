import Foundation

public struct ProfileDto: Codable, Sendable {
    public let user: UserDto
    public let email: String
    public let emailVerified: Bool

    public init(user: UserDto, email: String, emailVerified: Bool) {
        self.user = user
        self.email = email
        self.emailVerified = emailVerified
    }
}
