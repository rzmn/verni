import Api

public struct Operation: Sendable, Hashable, Equatable, Codable {
    public enum Kind: Sendable, Hashable, Equatable, Codable {
        case pendingSync
        case pendingConfirm
        case synced
    }
    public var kind: Kind
    public var payload: Components.Schemas.SomeOperation

    public init(kind: Kind, payload: Components.Schemas.SomeOperation) {
        self.kind = kind
        self.payload = payload
    }
}

public protocol BaseOperationConvertible: Sendable {
    var base: Components.Schemas.BaseOperation { get }
}

extension Operation: BaseOperationConvertible {
    public var base: Components.Schemas.BaseOperation {
        payload.value1
    }
}

extension Components.Schemas.SomeOperation: BaseOperationConvertible {
    public var base: Components.Schemas.BaseOperation {
        value1
    }
}
