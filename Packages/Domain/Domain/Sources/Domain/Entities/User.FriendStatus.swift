extension User {
    public enum FriendStatus: Sendable {
        case currentUser
        case outgoing
        case incoming
        case friend
        case notAFriend
    }
}
