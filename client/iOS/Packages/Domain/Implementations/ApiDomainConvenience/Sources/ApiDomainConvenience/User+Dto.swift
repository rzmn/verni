import Domain
import DataTransferObjects
import UIKit

extension User {
    public init(dto: UserDto) {
        let data = dto.avatar.url.flatMap {
            NSData.init(base64Encoded: $0) as Data?
        }
        self = User(
            id: dto.id,
            status: User.FriendStatus(dto: dto.friendStatus),
            displayName: dto.displayName,
            avatar: data.flatMap(UIImage.init)
        )
    }
}

extension UserDto {
    public init(domain user: User) {
        self = UserDto(
            login: user.id,
            friendStatus: FriendStatus(domain: user.status),
            displayName: user.displayName,
            avatar: Avatar(url: user.avatar?.pngData()?.base64EncodedString())
        )
    }
}
