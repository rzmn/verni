import Combine

public enum FriendshipKind: Int, CaseIterable {
    case friends
    case incoming
    case pending
}

public struct FriendshipKindSet: OptionSet {
    public var rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    public init(element: FriendshipKind) {
        self.init(rawValue: 1 << element.rawValue)
    }
    public static let friends = FriendshipKindSet(rawValue: 1 << FriendshipKind.friends.rawValue)
    public static let incoming = FriendshipKindSet(rawValue: 1 << FriendshipKind.incoming.rawValue)
    public static let pending = FriendshipKindSet(rawValue: 1 << FriendshipKind.pending.rawValue)
}

public protocol FriendsRepository {
    func getFriends(set: FriendshipKindSet) async -> Result<[FriendshipKind: [User]], RepositoryError>
    var friendsUpdated: AnyPublisher<Void, Never> { get }
}
