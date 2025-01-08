import Domain
import Api

extension User {
    public init(dto: Components.Schemas.User) {
        self = User(
            id: dto.id,
            ownerId: dto.ownerId,
            displayName: dto.displayName,
            avatar: dto.avatarId
        )
    }
}

extension Components.Schemas.User {
    public init(domain user: User) {
        self = Components.Schemas.User(
            id: user.id,
            ownerId: user.ownerId,
            displayName: user.displayName,
            avatarId: user.avatar
        )
    }
}
