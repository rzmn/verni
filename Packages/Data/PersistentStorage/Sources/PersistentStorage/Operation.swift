import Api
import Domain

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

public protocol BaseOperationConvertible {
    var base: Components.Schemas.BaseOperation { get }
}

extension Operation: BaseOperationConvertible {
    public var base: Components.Schemas.BaseOperation {
        payload.value1
    }
}

extension Components.Schemas.Operation: BaseOperationConvertible {
    public var base: Components.Schemas.BaseOperation {
        value1
    }
}
