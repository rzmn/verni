public protocol FriendsOfflineMutableRepository: Sendable {
    func storeFriends(_ friends: [FriendshipKind: [User]]) async
}
