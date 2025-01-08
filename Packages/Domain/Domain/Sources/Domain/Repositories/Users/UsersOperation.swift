import Foundation

public struct UsersOperation: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case displayNameUpdated(User.Identifier, name: String)
        case avatarUpdated(User.Identifier, avatar: Avatar.Identifier)
        case userCreated(User.Identifier, owner: User.Identifier, name: String)
    }
    public let kind: Kind
    public let id: String
    public let timestamp: TimeInterval
}
