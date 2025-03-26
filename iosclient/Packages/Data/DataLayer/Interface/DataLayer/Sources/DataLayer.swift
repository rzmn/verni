import Api
import AsyncExtensions
import PersistentStorage

public protocol DataLayer: Sendable {
    var available: [DataLayerPreview] { get async }
    
    var sandbox: DataSession { get }
    
    func create(
        startupData: Components.Schemas.StartupData,
        deviceId: String,
        loggedOutHandler: EventPublisher<Void>
    ) async throws -> (DataSession, UserStorage)
    
    func deleteSession(hostId: HostId) async
}
