import Domain
import UIKit

extension User {
    public init(dto: UserDto) {
        let data = dto.avatarId.flatMap {
            Avatar(id: $0)
        }
        self = User(
            id: dto.id,
            status: User.FriendStatus(dto: dto.friendStatus),
            displayName: dto.displayName,
            avatar: data
        )
    }
}

extension UserDto {
    public init(domain user: User) {
        self = UserDto(
            login: user.id,
            friendStatus: FriendStatus(domain: user.status),
            displayName: user.displayName,
            avatarId: user.avatar?.id
        )
    }
}
