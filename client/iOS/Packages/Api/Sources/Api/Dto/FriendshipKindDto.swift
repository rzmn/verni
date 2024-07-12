import Foundation

public enum FriendshipKindDto: Int, Decodable {
    case friends = 1
    case subscription = 2
    case subscriber = 3
}
