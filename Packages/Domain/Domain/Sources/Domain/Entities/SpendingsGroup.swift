import Foundation

public struct LocalOnlySpendingsGroup: Sendable, Equatable {
    public let id: SpendingsGroup.Identifier
    public let name: String?
    public let participants: [User.Identifier]
    public let createdAt: TimeInterval
    public let spendings: [Spending.Payload]

    public init(
        id: SpendingsGroup.Identifier,
        name: String?,
        participants: [User.Identifier],
        createdAt: TimeInterval,
        spendings: [Spending.Payload]
    ) {
        self.id = id
        self.name = name
        self.participants = participants
        self.createdAt = createdAt
        self.spendings = spendings
    }
}

public struct SpendingsGroup: Sendable, Equatable {
    public let id: Identifier
    public let name: String?
    public let createdAt: TimeInterval
    public let participants: [Participant]
    public let spendings: [Spending]

    public init(
        id: Identifier,
        name: String?,
        createdAt: TimeInterval,
        participants: [Participant],
        spendings: [Spending]
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.participants = participants
        self.spendings = spendings
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
