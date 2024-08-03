import Base

public struct UserDto: Codable {
    public enum FriendStatus: Int, Codable {
        case no = 0
        case incomingRequest = 1
        case outgoingRequest = 2
        case friends = 3
        case me = 4
    }
    public typealias ID = String
    public let id: ID
    public let friendStatus: FriendStatus

    public init(login: ID, friendStatus: FriendStatus) {
        self.id = login
        self.friendStatus = friendStatus
    }
}

extension UserDto: CompactDescription {}
