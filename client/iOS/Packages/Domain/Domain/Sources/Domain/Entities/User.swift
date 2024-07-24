public struct User {
    public let id: ID
    public let status: FriendStatus

    public init(id: ID, status: FriendStatus = .no) {
        self.id = id
        self.status = status
    }
}

extension User {
    public typealias ID = String
}
