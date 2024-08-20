import Combine

public enum FriendshipKind: Int, CaseIterable, Hashable {
    case friends
    case incoming
    case pending
}

public protocol FriendsRepository {
    func getFriends(set: Set<FriendshipKind>) async -> Result<[FriendshipKind: [User]], GeneralError>

    func friendsUpdated() async -> AnyPublisher<Void, Never>
}

public protocol FriendsOfflineRepository {
    func getFriends(set: Set<FriendshipKind>) async -> [FriendshipKind: [User]]?
}

public protocol FriendsOfflineMutableRepository: FriendsOfflineRepository {
    func storeFriends(_ friends: [FriendshipKind: [User]]) async
}
