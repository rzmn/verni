import Foundation
import PersistentStorage
import Api
import AsyncExtensions
internal import Convenience
internal import DefaultApiImplementation

actor RefreshTokenManager {
    private let api: APIProtocol
    private let persistency: UserStorage
    private var accessTokenValue: String?
    private let authenticationLostSubject: AsyncSubject<Void>

    init(
        api: APIProtocol,
        persistency: UserStorage,
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
            if let error = error.noConnection {
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
        do {
            try await persistency.update(refreshToken: session.refreshToken)
        } catch {
            await authenticationLostSubject.yield(())
            throw .internalError(error)
        }
    }
}
