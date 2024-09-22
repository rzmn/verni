import Api
import DataTransferObjects
import PersistentStorage
import DataLayerDependencies
import AsyncExtensions

final class DefaultAuthenticatedDataLayerSession: AuthenticatedDataLayerSession {
    let api: ApiProtocol
    let longPoll: LongPoll
    let persistency: Persistency
    let authenticationLostHandler: any AsyncBroadcast<Void>

    init(
        api: ApiProtocol,
        longPoll: LongPoll,
        persistency: Persistency,
        authenticationLostHandler: any AsyncBroadcast<Void>
    ) {
        self.api = api
        self.persistency = persistency
        self.authenticationLostHandler = authenticationLostHandler
        self.longPoll = longPoll
    }
}
