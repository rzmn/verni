import Foundation
import PersistentStorage
import Api
import AsyncExtensions
internal import Base
internal import DefaultApiImplementation

actor RefreshTokenManager {
    private let api: APIProtocol
    private let persistency: Persistency
    private var accessTokenValue: String?
    private let authenticationLostSubject: AsyncSubject<Void>

    init(
        api: APIProtocol,
        persistency: Persistency,
        authenticationLostSubject: AsyncSubject<Void>,
        accessToken: String?
    ) {
        self.api = api
        self.persistency = persistency
        self.authenticationLostSubject = authenticationLostSubject
        self.accessTokenValue = accessToken
    }
}

extension RefreshTokenManager: RefreshTokenRepository {
    func accessToken() async -> String? {
        accessTokenValue
    }

    func refreshTokens() async throws(RefreshTokenFailureReason) {
        let response: Operations.RefreshSession.Output
        do {
            response = try await api.refreshSession(
                body: .json(
                    .init(
                        refreshToken: await persistency.refreshToken
                    )
                )
            )
        } catch {
            if let error = error as? URLError, error.code == .notConnectedToInternet {
                throw .noConnection(error)
            } else {
                await authenticationLostSubject.yield(())
                throw .internalError(error)
            }
        }
        let session: Components.Schemas.Session
        switch response {
        case .ok(let sessionFromApi):
            switch sessionFromApi.body {
            case .json(let payload):
                session = payload.response
            }
        case .unauthorized(let error):
            await authenticationLostSubject.yield(())
            throw .expired(ErrorContext(context: error))
        case .conflict, .internalServerError, .undocumented:
            await authenticationLostSubject.yield(())
            throw .internalError(ErrorContext(context: response))
        }
        accessTokenValue = session.accessToken
        await persistency.update(value: session.refreshToken, for: Schema.refreshToken.unkeyed)
    }
}
