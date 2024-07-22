import Domain
import DataTransferObjects

extension User.FriendStatus {
    public init(dto: UserDto.FriendStatus) {
        switch dto {
        case .no:
            self = .no
        case .incomingRequest:
            self = .incoming
        case .outgoingRequest:
            self = .outgoing
        case .friends:
            self = .friend
        case .me:
            self = .me
        }
    }
}

extension UserDto.FriendStatus {
    public init(domain: User.FriendStatus) {
        switch domain {
        case .no:
            self = .no
        case .incoming:
            self = .incomingRequest
        case .outgoing:
            self = .outgoingRequest
        case .friend:
            self = .friends
        case .me:
            self = .me
        }
    }
}
