import Domain
import PersistentStorage
internal import ApiDomainConvenience
internal import DataTransferObjects

public actor DefaultFriendsOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultFriendsOfflineRepository: FriendsOfflineRepository {
    public func getFriends(set: FriendshipKindSet) async -> [FriendshipKind: [User]]? {
        await persistency.getFriends(set: Set(set.array.map(FriendshipKindDto.init))).flatMap {
            $0.reduce(into: [:]) { dict, item in
                dict[FriendshipKind(dto: item.key)] = item.value.map(User.init)
            }
        }
    }
}

extension DefaultFriendsOfflineRepository: FriendsOfflineMutableRepository {
    public func storeFriends(_ friends: [FriendshipKind: [User]], for set: FriendshipKindSet) async {
        await persistency.update(
            friends: friends.reduce(into: [:], { dict, item in
                dict[FriendshipKindDto(domain: item.key)] = item.value.map(UserDto.init)
            }),
            for: Set(set.array.map(FriendshipKindDto.init))
        )
    }
}
