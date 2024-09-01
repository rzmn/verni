public enum FriendshipKind: Int, CaseIterable, Hashable, Sendable {
    case friends
    case incoming
    case pending
}

public struct FriendshipKindSet: OptionSet, Hashable, Sendable {
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
