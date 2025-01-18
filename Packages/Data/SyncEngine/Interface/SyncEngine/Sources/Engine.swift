import AsyncExtensions
import Api

public protocol Engine: Sendable {
    var updates: any AsyncBroadcast<[Components.Schemas.Operation]> { get async }
    
    var operations: [Components.Schemas.Operation] { get async }
    
    func push(operations: [Components.Schemas.Operation]) async throws
    func pulled(operations: [Components.Schemas.Operation]) async throws
}

extension Engine {
    public func push(operation: Components.Schemas.Operation) async throws {
        try await push(operations: [operation])
    }
    
    public func pulled(operation: Components.Schemas.Operation) async throws {
        try await pulled(operations: [operation])
    }
}
