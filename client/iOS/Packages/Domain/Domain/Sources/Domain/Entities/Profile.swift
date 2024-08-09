public struct Profile: Equatable {
    public let user: User
    public let email: String
    public let isEmailVerified: Bool

    public init(user: User, email: String, isEmailVerified: Bool) {
        self.user = user
        self.email = email
        self.isEmailVerified = isEmailVerified
    }
}
