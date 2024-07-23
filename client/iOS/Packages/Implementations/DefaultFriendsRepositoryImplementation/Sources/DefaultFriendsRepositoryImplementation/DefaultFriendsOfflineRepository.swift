import Domain
import PersistentStorage

public class DefaultFriendsOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultFriendsOfflineRepository: FriendsOfflineRepository {
    public func getFriends(set: Set<FriendshipKind>) async -> [FriendshipKind : [User]]? {
        await persistency.getFriends(set: set)
    }
}

extension DefaultFriendsOfflineRepository: FriendsOfflineMutableRepository {
    public func storeFriends(_ friends: [FriendshipKind : [User]]) async {
        await persistency.storeFriends(friends)
    }
}
