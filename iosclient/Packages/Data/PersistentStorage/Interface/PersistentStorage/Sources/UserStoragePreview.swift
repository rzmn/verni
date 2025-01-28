public protocol UserStoragePreview: Sendable {
    var hostId: HostId { get }
    
    func awake() async throws -> UserStorage
}
