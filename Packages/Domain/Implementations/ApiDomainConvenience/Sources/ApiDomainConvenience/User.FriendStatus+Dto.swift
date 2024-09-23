import Domain
import DataTransferObjects

extension User.FriendStatus {
    public init(dto: UserDto.FriendStatus) {
        switch dto {
        case .notAFriend:
            self = .notAFriend
        case .incomingRequest:
            self = .incoming
        case .outgoingRequest:
            self = .outgoing
        case .friends:
            self = .friend
        case .currentUser:
            self = .currentUser
        }
    }
}

extension UserDto.FriendStatus {
    public init(domain: User.FriendStatus) {
        switch domain {
        case .notAFriend:
            self = .notAFriend
        case .incoming:
            self = .incomingRequest
        case .outgoing:
            self = .outgoingRequest
        case .friend:
            self = .friends
        case .currentUser:
            self = .currentUser
        }
    }
}
