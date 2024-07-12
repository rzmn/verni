import Base

public struct UserDto: Decodable {
    public enum FriendStatus: Int, Decodable {
        case no = 0
        case incomingRequest = 1
        case outgoingRequest = 2
        case friends = 3
        case me = 4
    }
    public typealias ID = String
    public let login: ID
    public let friendStatus: FriendStatus
}

extension UserDto: CompactDescription {}
