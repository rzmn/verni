import Foundation

public struct SpendingsGroup: Sendable, Equatable {
    public let id: Identifier
    public let name: String?
    public let createdAt: TimeInterval

    public init(
        id: Identifier,
        name: String?,
        createdAt: TimeInterval
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

extension SpendingsGroup {
    public struct Participant: Sendable, Equatable {
        public let userId: User.Identifier
        public let status: Status

        public init(userId: User.Identifier, status: Status) {
            self.userId = userId
            self.status = status
        }
    }
}

extension SpendingsGroup.Participant {
    public enum Status: Sendable, Equatable {
        case invited
        case member
        case declined
    }
}

extension SpendingsGroup {
    public typealias Identifier = String
}
