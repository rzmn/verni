import Api

public protocol SandboxStorage: Storage {
    var userId: HostId { get async }
    var operations: [Components.Schemas.SomeOperation] { get async }

    func update(operations: [Components.Schemas.SomeOperation]) async throws
}

extension SandboxStorage {
    public var userId: HostId {
        get async {
            .sandbox
        }
    }
}
