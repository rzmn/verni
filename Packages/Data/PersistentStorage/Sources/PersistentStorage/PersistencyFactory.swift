import Api

public protocol PersistencyFactory: Sendable {
    func awake(host: HostId) async -> Persistency?
    func create(
        host: HostId,
        refreshToken: String,
        operations: [Operation]
    ) async throws -> Persistency
}
