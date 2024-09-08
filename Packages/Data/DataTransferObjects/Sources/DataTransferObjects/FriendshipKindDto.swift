import Foundation

public enum FriendshipKindDto: Int, CaseIterable, Codable, Sendable {
    case friends = 1
    case subscription = 2
    case subscriber = 3
}
