import AsyncExtensions

public protocol DataLayerPreview: Sendable {
    var hostId: HostId { get }
    
    func awake(
        loggedOutHandler: EventPublisher<Void>
    ) async throws -> DataSession
}
