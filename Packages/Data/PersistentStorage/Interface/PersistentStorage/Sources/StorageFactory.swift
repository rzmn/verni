import Api

public protocol StorageFactory: Sendable {
    var sandbox: SandboxStorage { get }
    var hostsAvailable: [UserStoragePreview] { get async throws }
    
    func create(
        host: HostId,
        refreshToken: String,
        operations: [Operation]
    ) async throws -> UserStorage
}
