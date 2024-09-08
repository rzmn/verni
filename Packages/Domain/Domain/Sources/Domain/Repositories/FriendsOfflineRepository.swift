public protocol FriendsOfflineRepository: Sendable {
    func getFriends(set: FriendshipKindSet) async -> [FriendshipKind: [User]]?
}
