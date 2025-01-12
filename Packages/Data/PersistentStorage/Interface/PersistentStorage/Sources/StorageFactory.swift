import Api

public protocol StorageFactory: Sendable {
    func awake(
        host: HostId
    ) async -> UserStorage?
    
    func create(
        host: HostId,
        refreshToken: String,
        operations: [Operation]
    ) async throws -> UserStorage
    
    func sandbox() throws -> SandboxStorage
}
