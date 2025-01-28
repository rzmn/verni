import AsyncExtensions

public protocol DataLayerPreview: Sendable {
    var hostId: HostId { get }
    
    func awake(
        loggedOutHandler: AsyncSubject<Void>
    ) async throws -> DataSession
}
