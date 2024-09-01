import Combine

public enum FriendshipKind: Int, CaseIterable, Hashable {
    case friends
    case incoming
    case pending
}

public struct FriendshipKindSet: OptionSet, Hashable {
    public static let friends = FriendshipKindSet(rawValue: 1 << FriendshipKind.friends.rawValue)
    public static let incoming = FriendshipKindSet(rawValue: 1 << FriendshipKind.incoming.rawValue)
    public static let pending = FriendshipKindSet(rawValue: 1 << FriendshipKind.pending.rawValue)

    public static var all: FriendshipKindSet {
        FriendshipKind.allCases.reduce(into: []) { set, value in
            set.insert(FriendshipKindSet(rawValue: 1 << value.rawValue))
        }
    }

    public var array: [FriendshipKind] {
        FriendshipKind.allCases.filter {
            contains(FriendshipKindSet(rawValue: 1 << $0.rawValue))
        }
    }

    public var rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

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
