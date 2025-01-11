import Foundation

public struct SpendingGroup: Sendable, Equatable {
    public let id: Identifier
    public let name: String?
    public let createdAt: MsSince1970

    public init(
        id: Identifier,
        name: String?,
        createdAt: MsSince1970
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

extension SpendingGroup {
    public struct Participant: Sendable, Equatable {
        public let userId: User.Identifier
        public let status: Status

        public init(userId: User.Identifier, status: Status) {
            self.userId = userId
            self.status = status
        }
    }
}

extension SpendingGroup.Participant {
    public enum Status: Sendable, Equatable {
        case invited
        case member
        case declined
    }
}

extension SpendingGroup {
    public typealias Identifier = String
}
