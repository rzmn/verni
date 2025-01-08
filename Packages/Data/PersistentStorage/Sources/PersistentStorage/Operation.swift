import Foundation
import Api

public protocol IdentifiableOperation {
    var timestamp: TimeInterval { get }
    var id: String { get }
}

public protocol IdentifiableOperationConvertible: IdentifiableOperation {
    var identifiableOperation: IdentifiableOperation { get }
}

extension IdentifiableOperationConvertible {
    public var timestamp: TimeInterval {
        identifiableOperation.timestamp
    }

    public var id: String {
        identifiableOperation.id
    }
}

extension Components.Schemas.Operation: IdentifiableOperation {
    public var timestamp: TimeInterval {
        let createdAt: Int
        switch self {
        case .UpdateDisplayNameOperation(let operation):
            createdAt = operation.createdAt
        case .UpdateAvatarOperation(let operation):
            createdAt = operation.createdAt
        case .BindUserOperation(let operation):
            createdAt = operation.createdAt
        case .CreateUserOperation(let operation):
            createdAt = operation.createdAt
        }
        return TimeInterval(createdAt)
    }

    public var id: String {
        switch self {
        case .UpdateDisplayNameOperation(let operation):
            operation.operationId
        case .UpdateAvatarOperation(let operation):
            operation.operationId
        case .BindUserOperation(let operation):
            operation.operationId
        case .CreateUserOperation(let operation):
            operation.operationId
        }
    }
}

public struct Operation: Sendable, Hashable, Equatable, Codable {
    public enum Kind: Sendable, Hashable, Equatable, Codable {
        case pendingSync
        case pendingConfirm
        case synced
    }
    public var kind: Kind
    public var payload: Components.Schemas.Operation

    public init(kind: Kind, payload: Components.Schemas.Operation) {
        self.kind = kind
        self.payload = payload
    }
}

extension Operation: IdentifiableOperationConvertible {
    public var identifiableOperation: IdentifiableOperation {
        payload
    }
}
