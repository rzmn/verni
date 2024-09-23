import Base

public struct UserDto: Codable, Sendable, Equatable {
    public enum FriendStatus: Int, Codable, Sendable, Equatable {
        case notAFriend = 0
        case incomingRequest = 1
        case outgoingRequest = 2
        case friends = 3
        case currentUser = 4
    }
    public struct Avatar: Codable, Sendable, Equatable {
        public typealias Identifier = String

        public let id: Identifier?

        public init(id: Identifier?) {
            self.id = id
        }
    }
    public typealias Identifier = String
    public let id: Identifier
    public let friendStatus: FriendStatus
    public let displayName: String
    public let avatar: Avatar

    public init(login: Identifier, friendStatus: FriendStatus, displayName: String, avatar: Avatar) {
        self.id = login
        self.friendStatus = friendStatus
        self.displayName = displayName
        self.avatar = avatar
    }
}

extension UserDto: CompactDescription {}
