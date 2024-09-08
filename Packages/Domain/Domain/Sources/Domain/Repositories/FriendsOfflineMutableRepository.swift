public protocol FriendsOfflineMutableRepository: Sendable {
    func storeFriends(_ friends: [FriendshipKind: [User]], for set: FriendshipKindSet) async
}
