import AuthUseCase
import DomainLayer
import Entities
import Api
import DataLayer
import AsyncExtensions
import Logging
import LogoutUseCase
internal import Convenience

actor DefaultAuthUseCase {
    public let logger: Logger
    private let sharedDomain: DefaultSharedDomainLayer
    private let sessionHost: SessionHost

    init(
        sharedDomain: DefaultSharedDomainLayer,
        logger: Logger
    ) {
        self.sharedDomain = sharedDomain
        sessionHost = SessionHost()
        self.logger = logger
    }
}

extension DefaultAuthUseCase: AuthUseCase {
    public func awake() async throws(AwakeError) -> any HostedDomainLayer {
        guard let hostId = await sessionHost.activeSession else {
            throw .hasNoSession
        }
        let preview = await sharedDomain.data.available
            .first { $0.hostId == hostId }
        guard let preview else {
            await sessionHost.performIsolated { sessionHost in
                sessionHost.activeSession = nil
            }
            throw .hasNoSession
        }
        let logoutSubject = AsyncSubject<Void>(
            taskFactory: sharedDomain.infrastructure.taskFactory,
            logger: sharedDomain.infrastructure.logger
        )
        let session: DataSession
        do {
            session = try await preview.awake(
                loggedOutHandler: logoutSubject
            )
        } catch {
            throw .internalError(error)
        }
        return await DefaultHostedDomainLayer(
            sharedDomain: sharedDomain,
            logoutSubject: logoutSubject,
            sessionHost: sessionHost,
            dataSession: session,
            userId: hostId
        )
    }

    public func login(
        credentials: Credentials
    ) async throws(LoginError) -> any HostedDomainLayer {
        let response: Operations.Login.Output
        do {
            response = try await sharedDomain.data.sandbox.api.login(
                body: .json(
                    .init(
                        credentials: .init(
                            email: credentials.email,
                            password: credentials.password,
                            deviceId: await sessionHost.deviceId
                        )
                    )
                )
            )
        } catch {
            throw LoginError(error)
        }
        let startupData: Components.Schemas.StartupData
        switch response {
        case .ok(let success):
            switch success.body {
            case .json(let payload):
                startupData = payload.response
            }
        case .conflict(let apiError):
            throw LoginError(apiError)
        case .internalServerError(let apiError):
            throw LoginError(apiError)
        case .undocumented(statusCode: let statusCode, let body):
            logE { "got undocumented response on login: \(statusCode) \(body)" }
            throw LoginError(UndocumentedBehaviour(context: (statusCode, body)))
        }
        let session: HostedDomainLayer
        do {
            session = try await acquire(startupData: startupData)
        } catch {
            throw .other(error)
        }
        return session
    }

    public func signup(
        credentials: Credentials
    ) async throws(SignupError) -> any HostedDomainLayer {
        let response: Operations.Signup.Output
        do {
            response = try await sharedDomain.data.sandbox.api.signup(
                body: .json(
                    .init(
                        credentials: .init(
                            email: credentials.email,
                            password: credentials.password,
                            deviceId: await sessionHost.deviceId
                        )
                    )
                )
            )
        } catch {
            throw SignupError(error)
        }
        let startupData: Components.Schemas.StartupData
        switch response {
        case .ok(let success):
            switch success.body {
            case .json(let payload):
                startupData = payload.response
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
        let session: HostedDomainLayer
        do {
            session = try await acquire(startupData: startupData)
        } catch {
            throw .other(error)
        }
        return session
    }
    
    private func acquire(startupData: Components.Schemas.StartupData) async throws -> HostedDomainLayer {
        let logoutSubject = AsyncSubject<Void>(
            taskFactory: sharedDomain.infrastructure.taskFactory,
            logger: sharedDomain.infrastructure.logger
        )
        let session = try await sharedDomain.data.create(
            startupData: startupData,
            loggedOutHandler: logoutSubject
        )
        await sessionHost.performIsolated { sessionHost in
            sessionHost.activeSession = startupData.session.id
        }
        return await DefaultHostedDomainLayer(
            sharedDomain: sharedDomain,
            logoutSubject: logoutSubject,
            sessionHost: sessionHost,
            dataSession: session,
            userId: startupData.session.id
        )
    }
}

extension DefaultAuthUseCase: Loggable {}
