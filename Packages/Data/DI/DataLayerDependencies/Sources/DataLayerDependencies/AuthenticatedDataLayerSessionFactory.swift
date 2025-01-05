import Api
import PersistentStorage

public enum DataLayerAwakeError: Error, Sendable {
    case hasNoSession
    case internalError(Error)
}

public protocol AuthenticatedDataLayerSessionFactory: Sendable {
    func awakeAuthorizedSession() async throws(DataLayerAwakeError) -> AuthenticatedDataLayerSession

    func createAuthorizedSession(
        token: Components.Schemas.Session
    ) async throws -> AuthenticatedDataLayerSession
}
