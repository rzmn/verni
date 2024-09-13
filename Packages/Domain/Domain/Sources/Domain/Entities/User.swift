public struct User: Equatable, Sendable {
    public let id: ID
    public let status: FriendStatus
    public let displayName: String
    public let avatar: Avatar?

    public init(
        id: ID,
        status: FriendStatus,
        displayName: String,
        avatar: Avatar?
    ) {
        self.id = id
        self.status = status
        self.displayName = displayName
        self.avatar = avatar
    }

    public init(
        _ user: User,
        id: ID? = nil,
        status: FriendStatus? = nil,
        displayName: String? = nil,
        avatar: Avatar?? = nil
    ) {
        self.init(
            id: id ?? user.id,
            status: status ?? user.status,
            displayName: displayName ?? user.displayName,
            avatar: avatar == nil ? user.avatar : avatar?.map { $0 }
        )
    }
}

extension User {
    public typealias ID = String
}
