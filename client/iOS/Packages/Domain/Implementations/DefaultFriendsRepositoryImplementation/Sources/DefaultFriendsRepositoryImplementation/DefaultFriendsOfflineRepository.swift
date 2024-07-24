import Domain
import PersistentStorage
internal import ApiDomainConvenience
internal import DataTransferObjects

public class DefaultFriendsOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultFriendsOfflineRepository: FriendsOfflineRepository {
    public func getFriends(set: Set<FriendshipKind>) async -> [FriendshipKind : [User]]? {
        await persistency.getFriends(set: Set(set.map(FriendshipKindDto.init))).flatMap {
            $0.reduce(into: [:]) { dict, item in
                dict[FriendshipKind(dto: item.key)] = item.value.map(User.init)
            }
        }
    }
}

extension DefaultFriendsOfflineRepository: FriendsOfflineMutableRepository {
    public func storeFriends(_ friends: [FriendshipKind : [User]]) async {
        await persistency.storeFriends(
            friends.reduce(into: [:], { dict, item in
                dict[FriendshipKindDto(domain: item.key)] = item.value.map(UserDto.init)
            })
        )
    }
}
