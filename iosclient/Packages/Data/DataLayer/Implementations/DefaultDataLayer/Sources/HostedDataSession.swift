import DataLayer
import Api
import SyncEngine

final class HostedDataSession: DataSession {
    let api: APIProtocol
    let sync: Engine
    
    init(api: APIProtocol, sync: Engine) {
        self.api = api
        self.sync = sync
    }
}
