extension User {
    public enum FriendStatus: Sendable {
        case me
        case outgoing
        case incoming
        case friend
        case no
    }
}
