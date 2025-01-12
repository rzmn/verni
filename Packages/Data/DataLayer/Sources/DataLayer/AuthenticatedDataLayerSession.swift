import Api
import PersistentStorage
import AsyncExtensions

public protocol AuthenticatedDataLayerSession: Sendable {
    var api: APIProtocol { get }
    var remoteUpdates: RemoteUpdatesService { get }
    var persistency: UserStorage { get }

    var authenticationLostHandler: any AsyncBroadcast<Void> { get }

    func logout() async
}
