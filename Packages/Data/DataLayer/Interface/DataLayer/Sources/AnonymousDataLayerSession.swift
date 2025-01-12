import Api
import SyncEngine
import PersistentStorage
import InfrastructureLayer

public protocol AnonymousDataLayerSession: Sendable {
    var api: APIProtocol { get }
    var sync: Engine { get async }
    var storage: SandboxStorage { get }
    var infrastructure: InfrastructureLayer { get }
    
    var authenticator: AuthenticatedDataLayerSessionFactory { get }
}
