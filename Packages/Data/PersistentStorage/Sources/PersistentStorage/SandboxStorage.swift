import Api

public protocol SandboxStorage: Storage {
    var userId: HostId { get async }
    var operations: [Components.Schemas.Operation] { get async }
    
    func update(operations: [Components.Schemas.Operation]) async throws
}

extension SandboxStorage {
    public var userId: HostId {
        get async {
            .sandbox
        }
    }
}
