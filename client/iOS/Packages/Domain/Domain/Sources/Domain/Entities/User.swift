public struct User: Equatable, Sendable {
    public let id: ID
    public let status: FriendStatus
    public let displayName: String
    public let avatar: Avatar?

    public init(id: ID, status: FriendStatus = .no, displayName: String, avatar: Avatar?) {
        self.id = id
        self.status = status
        self.displayName = displayName
        self.avatar = avatar
    }
}

extension User {
    public typealias ID = String
}
