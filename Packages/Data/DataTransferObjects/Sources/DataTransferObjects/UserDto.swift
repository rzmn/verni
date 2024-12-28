import Base

public struct UserDto: Codable, Sendable, Equatable {
    public enum FriendStatus: Int, Codable, Sendable, Equatable {
        case notAFriend = 0
        case incomingRequest = 1
        case outgoingRequest = 2
        case friends = 3
        case currentUser = 4
    }
    public typealias Identifier = String
    public let id: Identifier
    public let displayName: String
    public let avatarId: ImageDto.Identifier?
    public let friendStatus: FriendStatus

    public init(
        login: Identifier,
        friendStatus: FriendStatus,
        displayName: String,
        avatarId: ImageDto.Identifier?
    ) {
        self.id = login
        self.friendStatus = friendStatus
        self.displayName = displayName
        self.avatarId = avatarId
    }
}

extension UserDto: CustomStringConvertible {
    public var description: String {
        "<(\(displayName)) id:\(id) st:\(friendStatus.rawValue) av:\(avatarId ?? "<nil>")>"
    }
}
