import Api
import PersistentStorage

public protocol AnonymousDataLayerSession: Sendable {
    var api: APIProtocol { get }
    var storage: SandboxStorage { get }
    var authenticator: AuthenticatedDataLayerSessionFactory { get }
}
