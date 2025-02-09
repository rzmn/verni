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
    let logger: Logger
    private let sharedDomain: DefaultSharedDomainLayer
    private let sessionHost: SessionHost

    init(
        sharedDomain: DefaultSharedDomainLayer,
        logger: Logger
    ) {
        self.sharedDomain = sharedDomain
        self.sessionHost = SessionHost()
        self.logger = logger
    }
}

extension DefaultAuthUseCase: AuthUseCase {
    func awake() async throws(AwakeError) -> any HostedDomainLayer {
        guard let hostId = await sessionHost.activeSession else {
            logI { "no session host found" }
            throw .hasNoSession
        }
        let preview = await sharedDomain.data.available
            .first { $0.hostId == hostId }
        guard let preview else {
            logI { "session host \(hostId) found with no session, invalidating host" }
            await sessionHost.performIsolated { sessionHost in
                sessionHost.activeSession = nil
            }
            throw .hasNoSession
        }
        let logoutSubject = EventPublisher<Void>()
        let session: DataSession
        do {
            session = try await preview.awake(
                loggedOutHandler: logoutSubject
            )
        } catch {
            logE { "failed to awake existed session, host: \(hostId), error: \(error)" }
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

    func login(
        credentials: Credentials
    ) async throws(LoginError) -> any HostedDomainLayer {
        let response: Operations.Login.Output
        do {
            response = try await sharedDomain.data.sandbox.api.login(
                headers: Operations.Login.Input.Headers(
                    xDeviceID: await sessionHost.deviceId
                ),
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
        let startupData: Components.Schemas.StartupData
        do {
            startupData = try response.get()
        } catch {
            switch error {
            case .expected(let payload):
                logW { "login finished with error: \(payload)" }
                throw LoginError(payload)
            case .undocumented(let statusCode, let payload):
                logE { "login undocumented response code: \(statusCode), payload: \(payload)" }
                throw LoginError(error)
            }
        }
        let session: HostedDomainLayer
        do {
            session = try await acquire(startupData: startupData)
        } catch {
            throw .other(error)
        }
        return session
    }

    func signup(
        credentials: Credentials
    ) async throws(SignupError) -> any HostedDomainLayer {
        let response: Operations.Signup.Output
        do {
            response = try await sharedDomain.data.sandbox.api.signup(
                headers: Operations.Signup.Input.Headers(
                    xDeviceID: await sessionHost.deviceId
                ),
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
        let startupData: Components.Schemas.StartupData
        do {
            startupData = try response.get()
        } catch {
            switch error {
            case .expected(let payload):
                logW { "signup finished with error: \(payload)" }
                throw SignupError(payload)
            case .undocumented(let statusCode, let payload):
                logE { "signup undocumented response code: \(statusCode), payload: \(payload)" }
                throw SignupError(error)
            }
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
        let logoutSubject = EventPublisher<Void>()
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
