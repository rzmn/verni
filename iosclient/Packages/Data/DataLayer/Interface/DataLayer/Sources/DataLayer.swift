import Api
import Foundation
import AsyncExtensions
import PersistentStorage

public protocol DataLayer: Sendable {
    var available: [DataLayerPreview] { get async }
    
    var sandbox: DataSession { get }
    var userDefaults: Atomic<UserDefaults> { get }
    
    func create(
        startupData: Components.Schemas.StartupData,
        deviceId: String,
        loggedOutHandler: EventPublisher<Void>
    ) async throws -> (DataSession, UserStorage)
    
    func deleteSession(hostId: HostId) async
}
