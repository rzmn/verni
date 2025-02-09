import AsyncExtensions
import Api

public protocol Engine: Sendable {
    var updates: any EventSource<[Components.Schemas.SomeOperation]> { get async }
    
    var operations: [Components.Schemas.SomeOperation] { get async }
    
    func push(operations: [Components.Schemas.SomeOperation]) async throws
    func pulled(operations: [Components.Schemas.SomeOperation]) async throws
}

extension Engine {
    public func push(operation: Components.Schemas.SomeOperation) async throws {
        try await push(operations: [operation])
    }
    
    public func pulled(operation: Components.Schemas.SomeOperation) async throws {
        try await pulled(operations: [operation])
    }
}
