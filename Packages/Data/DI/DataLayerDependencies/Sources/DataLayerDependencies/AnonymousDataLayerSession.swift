import Api
import PersistentStorage

public protocol AnonymousDataLayerSession: Sendable {
    var api: APIProtocol { get }
    var authenticator: AuthenticatedDataLayerSessionFactory { get }
}
