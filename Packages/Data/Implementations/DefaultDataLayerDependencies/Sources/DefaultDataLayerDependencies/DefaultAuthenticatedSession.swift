import Api
import DataTransferObjects
import PersistentStorage
import DataLayerDependencies
import AsyncExtensions

final class DefaultAuthenticatedSession: AuthenticatedDataLayerSession {
    let api: ApiProtocol
    let longPoll: LongPoll
    let persistency: Persistency
    let authenticationLostHandler: any AsyncBroadcast<Void>
    private let sessionHost: SessionHost

    init(
        api: ApiProtocol,
        longPoll: LongPoll,
        persistency: Persistency,
        authenticationLostHandler: any AsyncBroadcast<Void>,
        sessionHost: SessionHost
    ) {
        self.api = api
        self.persistency = persistency
        self.authenticationLostHandler = authenticationLostHandler
        self.longPoll = longPoll
        self.sessionHost = sessionHost
    }

    func logout() async {
        await persistency.invalidate()
        await sessionHost.sessionFinished()
    }
}
