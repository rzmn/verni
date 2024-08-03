import Domain
import DataTransferObjects

extension User {
    public init(dto: UserDto) {
        self = User(id: dto.id, status: User.FriendStatus(dto: dto.friendStatus))
    }
}

extension UserDto {
    public init(domain user: User) {
        self = UserDto(login: user.id, friendStatus: FriendStatus(domain: user.status))
    }
}
