import Api
import DataTransferObjects
import PersistentStorage

public enum DataLayerAwakeError: Error, Sendable {
    case hasNoSession
    case internalError(Error)
}

public protocol AuthenticatedDataLayerSessionFactory: Sendable {
    func awakeAuthorizedSession() async throws(DataLayerAwakeError) -> AuthenticatedDataLayerSession

    func createAuthorizedSession(
        token: AuthTokenDto
    ) async throws -> AuthenticatedDataLayerSession
}
