import Foundation
import OpenAPIRuntime

public protocol Operation {
    var timestamp: TimeInterval { get }
    var id: String { get }
}

extension Components.Schemas.Operation: Operation {
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
