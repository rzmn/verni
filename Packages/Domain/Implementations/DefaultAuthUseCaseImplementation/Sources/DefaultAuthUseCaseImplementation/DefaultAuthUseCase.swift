import Domain
import Api
import PersistentStorage
import DI
import AsyncExtensions
import DataLayerDependencies
import Logging
import Base

public actor DefaultAuthUseCase {
    public let logger: Logger
    private let taskFactory: TaskFactory
    private let dataLayer: AnonymousDataLayerSession

    public init(
        taskFactory: TaskFactory,
        dataLayer: AnonymousDataLayerSession,
        logger: Logger
    ) {
        self.logger = logger
        self.taskFactory = taskFactory
        self.dataLayer = dataLayer
    }
}

extension DefaultAuthUseCase: AuthUseCase {
    public func awake() async throws(AwakeError) -> any AuthenticatedDataLayerSession {
        let dataLayer: AuthenticatedDataLayerSession
        do {
            dataLayer = try await self.dataLayer.authenticator.awakeAuthorizedSession()
        } catch {
            switch error {
            case .hasNoSession:
                throw .hasNoSession
            case .internalError(let error):
                throw .internalError(error)
            }
        }
        return dataLayer
    }

    public func login(
        credentials: Credentials
    ) async throws(LoginError) -> any AuthenticatedDataLayerSession {
        let response: Operations.Login.Output
        do {
            response = try await dataLayer.api.login(
                body: .json(
                    .init(
                        credentials: .init(
                            email: credentials.email,
                            password: credentials.password
                        )
                    )
                )
            )
        } catch {
            throw LoginError(error)
        }
        let session: Components.Schemas.Session
        switch response {
        case .ok(let success):
            switch success.body {
            case .json(let payload):
                session = payload.response
            }
        case .conflict(let apiError):
            throw LoginError(apiError)
        case .internalServerError(let apiError):
            throw LoginError(apiError)
        case .undocumented(statusCode: let statusCode, let body):
            logE { "got undocumented response on login: \(statusCode) \(body)" }
            throw LoginError(UndocumentedBehaviour(context: (statusCode, body)))
        }
        do {
            return try await dataLayer.authenticator
                .createAuthorizedSession(session: session)
        } catch {
            throw .other(error)
        }
    }

    public func signup(
        credentials: Credentials
    ) async throws(SignupError) -> any AuthenticatedDataLayerSession {
        let response: Operations.Signup.Output
        do {
            response = try await dataLayer.api.signup(
                body: .json(
                    .init(
                        credentials: .init(
                            email: credentials.email,
                            password: credentials.password
                        )
                    )
                )
            )
        } catch {
            throw SignupError(error)
        }
        let session: Components.Schemas.Session
        switch response {
        case .ok(let success):
            switch success.body {
            case .json(let payload):
                session = payload.response
            }
        case .conflict(let apiError):
            throw SignupError(apiError)
        case .unprocessableContent(let apiError):
            throw SignupError(apiError)
        case .internalServerError(let apiError):
            throw SignupError(apiError)
        case .undocumented(statusCode: let statusCode, let body):
            logE { "got undocumented response on signup: \(statusCode) \(body)" }
            throw SignupError(UndocumentedBehaviour(context: (statusCode, body)))
        }
        do {
            return try await dataLayer.authenticator
                .createAuthorizedSession(session: session)
        } catch {
            throw .other(error)
        }
    }
}

extension DefaultAuthUseCase: Loggable {}
