public struct User: Equatable, Sendable {
    public var id: Identifier
    public var ownerId: Identifier
    public var displayName: String
    public var avatar: Avatar.Identifier?

    public init(
        id: Identifier,
        ownerId: Identifier,
        displayName: String,
        avatar: Avatar.Identifier?
    ) {
        self.id = id
        self.displayName = displayName
        self.avatar = avatar
        self.ownerId = ownerId
    }
}

extension User {
    public typealias Identifier = String
}
