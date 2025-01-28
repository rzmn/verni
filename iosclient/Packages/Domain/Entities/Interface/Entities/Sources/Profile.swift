public struct Profile: Equatable, Sendable {
    public enum Email: Sendable, Equatable {
        case undefined
        case email(String, verified: Bool)
    }
    
    public var userId: User.Identifier
    public var email: Email

    public init(
        userId: User.Identifier,
        email: Email
    ) {
        self.userId = userId
        self.email = email
    }
}
