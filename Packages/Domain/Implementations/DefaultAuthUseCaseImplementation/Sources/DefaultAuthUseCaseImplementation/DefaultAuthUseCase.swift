import Domain
import Api
import ApiService
import PersistentStorage
import DI
import AsyncExtensions
import DataLayerDependencies
internal import DataTransferObjects

public actor DefaultAuthUseCase {
    private let taskFactory: TaskFactory
    private let dataLayer: AnonymousDataLayerSession

    public init(
        taskFactory: TaskFactory,
        dataLayer: AnonymousDataLayerSession
    ) async {
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
        let token: AuthTokenDto
        do {
            token = try await dataLayer.api.run(
                method: Auth.Login(
                    credentials: CredentialsDto(
                        email: credentials.email,
                        password: credentials.password
                    )
                )
            )
        } catch {
            throw LoginError(apiError: error)
        }
        do {
            return try await dataLayer.authenticator
                .createAuthorizedSession(token: token)
        } catch {
            throw .other(error)
        }
    }

    public func signup(
        credentials: Credentials
    ) async throws(SignupError) -> any AuthenticatedDataLayerSession {
        let token: AuthTokenDto
        do {
            token = try await dataLayer.api.run(
                method: Auth.Signup(
                    credentials: CredentialsDto(
                        email: credentials.email,
                        password: credentials.password
                    )
                )
            )
        } catch {
            throw SignupError(apiError: error)
        }
        do {
            return try await dataLayer.authenticator
                .createAuthorizedSession(token: token)
        } catch {
            throw .other(error)
        }
    }
}
