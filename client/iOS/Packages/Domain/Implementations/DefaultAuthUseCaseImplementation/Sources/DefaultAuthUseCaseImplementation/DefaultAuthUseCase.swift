import Domain
import Api
import ApiService
import AuthSession
import DataTransferObjects
import PersistentStorage
import DI

public class DefaultAuthUseCase {
    private let api: ApiProtocol
    private let apiServiceFactory: ApiServiceFactory
    private let persistencyFactory: PersistencyFactory
    private let activeSessionDIContainerFactory: ActiveSessionDIContainerFactory
    private let apiFactoryProvider: (TokenRefresher) -> ApiFactory

    public init(
        api: ApiProtocol,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory,
        activeSessionDIContainerFactory: ActiveSessionDIContainerFactory,
        apiFactoryProvider: @escaping (TokenRefresher) -> ApiFactory
    ) {
        self.api = api
        self.apiServiceFactory = apiServiceFactory
        self.persistencyFactory = persistencyFactory
        self.apiFactoryProvider = apiFactoryProvider
        self.activeSessionDIContainerFactory = activeSessionDIContainerFactory
    }
}

extension DefaultAuthUseCase: AuthUseCase {
    public func awake() async -> Result<ActiveSessionDIContainerConvertible, AwakeError> {
        guard let session = await ActiveSession.awake(
            anonymousApi: api,
            apiServiceFactory: apiServiceFactory,
            persistencyFactory: persistencyFactory, 
            activeSessionDIContainerFactory: activeSessionDIContainerFactory,
            apiFactoryProvider: apiFactoryProvider
        ) else {
            return.failure(.hasNoSession)
        }
        return .success(session)
    }
    
    public func login(credentials: Credentials) async -> Result<ActiveSessionDIContainerConvertible, LoginError> {
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
                return .failure(.noConnection(error))
            case .internalError(let error):
                return .failure(.other(error))
            }
            switch errorCode {
            case .incorrectCredentials:
                return .failure(.incorrectCredentials(error))
            case .wrongCredentialsFormat:
                return .failure(.wrongFormat(error))
            default:
                return .failure(.other(error))
            }
        }
        do {
            return .success(
                try await ActiveSession.awake(
                    anonymousApi: api,
                    hostId: token.id,
                    accessToken: token.accessToken,
                    refreshToken: token.refreshToken,
                    apiServiceFactory: apiServiceFactory,
                    persistencyFactory: persistencyFactory,
                    activeSessionDIContainerFactory: activeSessionDIContainerFactory,
                    apiFactoryProvider: apiFactoryProvider
                )
            )
        } catch {
            return .failure(.other(error))
        }
    }
    
    public func signup(credentials: Credentials) async -> Result<ActiveSessionDIContainerConvertible, SignupError> {
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
                return .failure(.noConnection(error))
            case .internalError(let error):
                return .failure(.other(error))
            }
            switch errorCode {
            case .loginAlreadyTaken:
                return .failure(.alreadyTaken(error))
            case .wrongCredentialsFormat:
                return .failure(.wrongFormat(error))
            default:
                return .failure(.other(error))
            }
        }
        do {
            return .success(
                try await ActiveSession.awake(
                    anonymousApi: api,
                    hostId: token.id,
                    accessToken: token.accessToken,
                    refreshToken: token.refreshToken,
                    apiServiceFactory: apiServiceFactory,
                    persistencyFactory: persistencyFactory,
                    activeSessionDIContainerFactory: activeSessionDIContainerFactory,
                    apiFactoryProvider: apiFactoryProvider
                )
            )
        } catch {
            return .failure(.other(error))
        }
    }
}
