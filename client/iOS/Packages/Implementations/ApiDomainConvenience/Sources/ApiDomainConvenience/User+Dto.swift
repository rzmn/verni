import Domain
import DataTransferObjects

extension User {
    public init(dto: UserDto) {
        self = User(id: dto.login, status: {
            switch dto.friendStatus {
            case .no:
                return .no
            case .incomingRequest:
                return .incoming
            case .outgoingRequest:
                return .outgoing
            case .friends:
                return .friend
            case .me:
                return .me
            }
        }())
    }
}
