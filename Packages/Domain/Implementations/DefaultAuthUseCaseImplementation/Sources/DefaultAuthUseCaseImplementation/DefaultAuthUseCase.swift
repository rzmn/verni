import Domain
import Api
import ApiService
import PersistentStorage
import DI
import AsyncExtensions
internal import DataTransferObjects

public actor DefaultAuthUseCase {
    private let taskFactory: TaskFactory
    private let api: ApiProtocol
    private let apiServiceFactory: ApiServiceFactory
    private let persistencyFactory: PersistencyFactory
    private let activeSessionDIContainerFactory: ActiveSessionDIContainerFactory
    private let apiFactoryProvider: @Sendable (TokenRefresher) async -> ApiFactory

    public init(
        taskFactory: TaskFactory,
        api: ApiProtocol,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory,
        activeSessionDIContainerFactory: ActiveSessionDIContainerFactory,
        apiFactoryProvider: @escaping @Sendable (TokenRefresher) async -> ApiFactory
    ) async {
        self.taskFactory = taskFactory
        self.api = api
        self.apiServiceFactory = apiServiceFactory
        self.persistencyFactory = persistencyFactory
        self.apiFactoryProvider = apiFactoryProvider
        self.activeSessionDIContainerFactory = activeSessionDIContainerFactory
    }
}

extension DefaultAuthUseCase: AuthUseCase {
    public func awake() async throws(AwakeError) -> any ActiveSessionDIContainerConvertible {
        guard let session = await ActiveSession.awake(
            taskFactory: taskFactory,
            anonymousApi: api,
            apiServiceFactory: apiServiceFactory,
            persistencyFactory: persistencyFactory,
            activeSessionDIContainerFactory: activeSessionDIContainerFactory,
            apiFactoryProvider: apiFactoryProvider
        ) else {
            throw .hasNoSession
        }
        return session
    }

    public func login(credentials: Credentials) async throws(LoginError) -> any ActiveSessionDIContainerConvertible {
        let token: AuthTokenDto
        do {
            token = try await api.run(
                method: Auth.Login(
                    credentials: CredentialsDto(
                        email: credentials.email,
                        password: credentials.password
                    )
                )
            )
        } catch {
            let errorCode: ApiErrorCode
            switch error {
            case .api(let code, _):
                errorCode = code
            case .noConnection(let error):
                throw .noConnection(error)
            case .internalError(let error):
                throw .other(error)
            }
            switch errorCode {
            case .incorrectCredentials:
                throw .incorrectCredentials(error)
            case .wrongCredentialsFormat:
                throw .wrongFormat(error)
            default:
                throw .other(error)
            }
        }
        do {
            return try await ActiveSession.create(
                taskFactory: taskFactory,
                anonymousApi: api,
                hostId: token.id,
                accessToken: token.accessToken,
                refreshToken: token.refreshToken,
                apiServiceFactory: apiServiceFactory,
                persistencyFactory: persistencyFactory,
                activeSessionDIContainerFactory: activeSessionDIContainerFactory,
                apiFactoryProvider: apiFactoryProvider
            )
        } catch {
            throw .other(error)
        }
    }

    public func signup(credentials: Credentials) async throws(SignupError) -> any ActiveSessionDIContainerConvertible {
        let token: AuthTokenDto
        do {
            token = try await api.run(
                method: Auth.Signup(
                    credentials: CredentialsDto(
                        email: credentials.email,
                        password: credentials.password
                    )
                )
            )
        } catch {
            let errorCode: ApiErrorCode
            switch error {
            case .api(let code, _):
                errorCode = code
            case .noConnection(let error):
                throw .noConnection(error)
            case .internalError(let error):
                throw .other(error)
            }
            switch errorCode {
            case .loginAlreadyTaken:
                throw .alreadyTaken(error)
            case .wrongCredentialsFormat:
                throw .wrongFormat(error)
            default:
                throw .other(error)
            }
        }
        do {
            return try await ActiveSession.create(
                taskFactory: taskFactory,
                anonymousApi: api,
                hostId: token.id,
                accessToken: token.accessToken,
                refreshToken: token.refreshToken,
                apiServiceFactory: apiServiceFactory,
                persistencyFactory: persistencyFactory,
                activeSessionDIContainerFactory: activeSessionDIContainerFactory,
                apiFactoryProvider: apiFactoryProvider
            )
        } catch {
            throw .other(error)
        }
    }
}
