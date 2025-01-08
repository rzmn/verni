public struct Profile: Equatable, Sendable {
    public var user: User
    public var email: String
    public var isEmailVerified: Bool

    public init(
        user: User,
        email: String,
        isEmailVerified: Bool
    ) {
        self.user = user
        self.email = email
        self.isEmailVerified = isEmailVerified
    }
}
