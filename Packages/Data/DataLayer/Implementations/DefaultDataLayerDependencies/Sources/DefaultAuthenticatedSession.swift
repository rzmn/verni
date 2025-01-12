import Api
import PersistentStorage
import DataLayerDependencies
import AsyncExtensions

final class DefaultAuthenticatedSession: AuthenticatedDataLayerSession {
    let api: APIProtocol
    let remoteUpdates: RemoteUpdatesService
    let persistency: UserStorage
    let authenticationLostHandler: any AsyncBroadcast<Void>
    private let sessionHost: SessionHost

    init(
        api: APIProtocol,
        remoteUpdates: RemoteUpdatesService,
        persistency: UserStorage,
        authenticationLostHandler: any AsyncBroadcast<Void>,
        sessionHost: SessionHost
    ) {
        self.api = api
        self.persistency = persistency
        self.authenticationLostHandler = authenticationLostHandler
        self.remoteUpdates = remoteUpdates
        self.sessionHost = sessionHost
    }

    func logout() async {
        await persistency.invalidate()
        await sessionHost.sessionFinished()
    }
}
