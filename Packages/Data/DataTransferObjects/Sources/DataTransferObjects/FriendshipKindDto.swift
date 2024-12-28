import Foundation

public enum FriendshipKindDto: Int, CaseIterable, Codable, Sendable {
    case friends = 1
    case subscription = 2
    case subscriber = 3
}

public struct FriendshipKindSetDto: OptionSet, Codable, Sendable, Hashable {
    public static let friends = Self(rawValue: 1 << FriendshipKindDto.friends.rawValue)
    public static let subscription = Self(rawValue: 1 << FriendshipKindDto.subscription.rawValue)
    public static let subscriber = Self(rawValue: 1 << FriendshipKindDto.subscriber.rawValue)

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init<S: Sequence>(_ array: S) where S.Element == FriendshipKindDto {
        self = array.reduce(into: []) { current, element in
            switch element {
            case .friends:
                current.insert(.friends)
            case .subscription:
                current.insert(.subscription)
            case .subscriber:
                current.insert(.subscriber)
            }
        }
    }

    public var array: [FriendshipKindDto] {
        FriendshipKindDto.allCases.filter {
            contains(Self([$0]))
        }
    }
}
