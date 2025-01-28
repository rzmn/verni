import Api
import SyncEngine

public protocol DataSession: Sendable {
    var api: APIProtocol { get }
    var sync: Engine { get async }
    
    func suspend() async
}
