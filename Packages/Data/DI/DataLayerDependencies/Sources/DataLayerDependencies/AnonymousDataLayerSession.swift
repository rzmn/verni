import Api
import DataTransferObjects
import PersistentStorage

public protocol AnonymousDataLayerSession: Sendable {
    var api: ApiProtocol { get }
    var authenticator: AuthenticatedDataLayerSessionFactory { get }
}
