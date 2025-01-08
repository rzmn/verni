import Api

public protocol SandboxStorage: Storage {
    var operations: [Components.Schemas.Operation] { get async }
    
    func update(operations: [Components.Schemas.Operation]) async throws
}
