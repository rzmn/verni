import Api
import PersistentStorage

public enum DataLayerAwakeError: Error, Sendable {
    case hasNoSession
    case internalError(Error)
}

public protocol AuthenticatedDataLayerSessionFactory: Sendable {
    func awakeAuthorizedSession() async throws(DataLayerAwakeError) -> AuthenticatedDataLayerSession

    func createAuthorizedSession(
        session: Components.Schemas.Session,
        operations: [Components.Schemas.Operation]
    ) async throws -> AuthenticatedDataLayerSession
}
