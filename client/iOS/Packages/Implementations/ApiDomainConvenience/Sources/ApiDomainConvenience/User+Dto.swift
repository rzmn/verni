import Domain
import DataTransferObjects

extension User {
    public init(dto: UserDto) {
        self = User(id: dto.login, status: User.FriendStatus(dto: dto.friendStatus))
    }
}
