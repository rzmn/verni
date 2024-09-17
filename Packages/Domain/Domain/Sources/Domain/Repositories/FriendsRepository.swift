import AsyncExtensions

public protocol FriendsRepository: Sendable {
    @discardableResult
    func refreshFriends(
        ofKind kind: FriendshipKindSet
    ) async throws(GeneralError) -> [FriendshipKind: [User]]

    func friendsUpdated(
        ofKind kind: FriendshipKindSet
    ) async -> any AsyncBroadcast<[FriendshipKind: [User]]>
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
