import Combine

public protocol FriendsRepository {
    @discardableResult
    func refreshFriends(
        ofKind kind: FriendshipKindSet
    ) async throws(GeneralError) -> [FriendshipKind: [User]]

    func friendsUpdated(
        ofKind kind: FriendshipKindSet
    ) async -> AnyPublisher<[FriendshipKind: [User]], Never>
}

public extension FriendsRepository {
    @discardableResult
    func refreshFriendsNoTypedThrow(ofKind kind: FriendshipKindSet) async -> Result<[FriendshipKind: [User]], GeneralError> {
        do {
            return .success(try await refreshFriends(ofKind: kind))
        } catch {
            return .failure(error)
        }
    }
}

public protocol FriendsOfflineRepository {
    func getFriends(set: FriendshipKindSet) async -> [FriendshipKind: [User]]?
}

public protocol FriendsOfflineMutableRepository: FriendsOfflineRepository {
    func storeFriends(_ friends: [FriendshipKind: [User]]) async
}
