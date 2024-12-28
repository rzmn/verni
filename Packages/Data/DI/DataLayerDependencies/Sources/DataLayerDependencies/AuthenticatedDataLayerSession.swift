import Api
import DataTransferObjects
import PersistentStorage
import AsyncExtensions

public protocol AuthenticatedDataLayerSession: Sendable {
    var api: ApiProtocol { get }
    var longPoll: LongPoll { get }
    var persistency: Persistency { get }

    var authenticationLostHandler: any AsyncBroadcast<Void> { get }

    func logout() async
}
