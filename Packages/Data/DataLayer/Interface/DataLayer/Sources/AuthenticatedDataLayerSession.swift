import Api
import SyncEngine
import PersistentStorage
import InfrastructureLayer
import AsyncExtensions

public protocol AuthenticatedDataLayerSession: Sendable {
    var api: APIProtocol { get }
    var sync: Engine { get }
    var storage: UserStorage { get }

    var authenticationLostHandler: any AsyncBroadcast<Void> { get }

    func logout() async
}
