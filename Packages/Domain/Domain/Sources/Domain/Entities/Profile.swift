public struct Profile: Equatable, Sendable {
    public var userId: User.Identifier
    public var email: String
    public var isEmailVerified: Bool

    public init(
        userId: User.Identifier,
        email: String,
        isEmailVerified: Bool
    ) {
        self.userId = userId
        self.email = email
        self.isEmailVerified = isEmailVerified
    }
}
