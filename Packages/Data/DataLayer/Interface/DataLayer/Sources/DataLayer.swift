import Api
import AsyncExtensions

public protocol DataLayer: Sendable {
    var available: [DataLayerPreview] { get async }
    
    var sandbox: DataSession { get }
    
    func create(
        startupData: Components.Schemas.StartupData,
        loggedOutHandler: AsyncSubject<Void>
    ) async throws -> DataSession
    
    func deleteSession(hostId: HostId) async
}
