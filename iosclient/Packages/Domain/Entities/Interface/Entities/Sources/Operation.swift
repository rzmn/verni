import Foundation

extension Operation {
    public typealias Identifier = String
}

public struct Operation: Sendable, Equatable {
    public enum EntityType: Sendable, Equatable {
        case user(AnyUser)
        case userRelation(from: AnyUser, to: AnyUser)
        case image(Image.Identifier)
        case spenginsGroup(SpendingGroup, [AnyUser])
        case spending(Spending, SpendingGroup.Identifier)
    }
    public enum Status: Sendable, Equatable {
        case pendingSync
        case pendingConfirm
        case synced
    }
    
    public let id: Identifier
    public let operationType: String
    public let operationStatus: Status
    public let author: AnyUser
    public let entityType: EntityType
    public let createdAt: MsSince1970
    public let details: String
    
    public init(
        id: Identifier,
        operationType: String,
        operationStatus: Status,
        author: AnyUser,
        entityType: EntityType,
        createdAt: MsSince1970,
        details: String
    ) {
        self.id = id
        self.operationType = operationType
        self.operationStatus = operationStatus
        self.author = author
        self.entityType = entityType
        self.createdAt = createdAt
        self.details = details
    }
}
