import Api
import PersistentStorage
import DataLayer
import SyncEngine
import InfrastructureLayer
import AsyncExtensions

final class DefaultAuthenticatedSession: AuthenticatedDataLayerSession {
    let api: APIProtocol
    let storage: UserStorage
    let sync: Engine
    let authenticationLostHandler: any AsyncBroadcast<Void>
    private let sessionHost: SessionHost

    init(
        api: APIProtocol,
        storage: UserStorage,
        sync: Engine,
        authenticationLostHandler: any AsyncBroadcast<Void>,
        sessionHost: SessionHost
    ) {
        self.api = api
        self.storage = storage
        self.sync = sync
        self.authenticationLostHandler = authenticationLostHandler
        self.sessionHost = sessionHost
    }

    func logout() async {
        await storage.invalidate()
        await sessionHost.sessionFinished()
    }
}
