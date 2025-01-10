import Api
import PersistentStorage
import Infrastructure

public protocol AnonymousDataLayerSession: Sendable {
    var api: APIProtocol { get }
    var storage: SandboxStorage { get }
    var infrastructure: InfrastructureLayer { get }
    var authenticator: AuthenticatedDataLayerSessionFactory { get }
}
