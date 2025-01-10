import Api
import Foundation

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

public protocol IdentifiableOperation {
    var timestamp: TimeInterval { get }
    var id: String { get }
    var authorId: String { get }
}

extension Components.Schemas.BaseOperation: IdentifiableOperation {
    public var timestamp: TimeInterval {
        TimeInterval(createdAt)
    }

    public var id: String {
        operationId
    }
}

public protocol IdentifiableOperationConvertible: IdentifiableOperation {
    var operation: IdentifiableOperation { get }
}

extension IdentifiableOperationConvertible {
    public var timestamp: TimeInterval {
        operation.timestamp
    }

    public var id: String {
        operation.id
    }
    
    public var authorId: String {
        operation.authorId
    }
}

extension Components.Schemas.Operation: IdentifiableOperationConvertible {
    public var operation: IdentifiableOperation {
        value1
    }
}

extension Operation: IdentifiableOperationConvertible {
    public var operation: IdentifiableOperation {
        payload
    }
}
