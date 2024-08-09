import Base

public struct UserDto: Codable {
    public enum FriendStatus: Int, Codable {
        case no = 0
        case incomingRequest = 1
        case outgoingRequest = 2
        case friends = 3
        case me = 4
    }
    public struct Avatar: Codable {
        public typealias ID = String

        public let id: ID?

        public init(id: ID?) {
            self.id = id
        }
    }
    public typealias ID = String
    public let id: ID
    public let friendStatus: FriendStatus
    public let displayName: String
    public let avatar: Avatar

    public init(login: ID, friendStatus: FriendStatus, displayName: String, avatar: Avatar) {
        self.id = login
        self.friendStatus = friendStatus
        self.displayName = displayName
        self.avatar = avatar
    }
}

extension UserDto: CompactDescription {}
