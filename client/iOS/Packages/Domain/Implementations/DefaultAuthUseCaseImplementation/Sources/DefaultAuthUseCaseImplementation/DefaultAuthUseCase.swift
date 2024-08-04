import Domain
import Api
import ApiService
import AuthSession
import DataTransferObjects
import PersistentStorage

public class DefaultAuthUseCase {
    private let api: ApiProtocol
    private let apiServiceFactory: ApiServiceFactory
    private let persistencyFactory: PersistencyFactory
    private let apiFactoryProvider: (TokenRefresher) -> ApiFactory

    public init(
        api: ApiProtocol,
        apiServiceFactory: ApiServiceFactory,
        persistencyFactory: PersistencyFactory,
        apiFactoryProvider: @escaping (TokenRefresher) -> ApiFactory
    ) {
        self.api = api
        self.apiServiceFactory = apiServiceFactory
        self.persistencyFactory = persistencyFactory
        self.apiFactoryProvider = apiFactoryProvider
    }
}

extension DefaultAuthUseCase: AuthUseCase {
    public func awake() async -> Result<ActiveSession, AwakeError> {
        guard let session = await ActiveSession.awake(
            anonymousApi: api,
            apiServiceFactory: apiServiceFactory,
            persistencyFactory: persistencyFactory,
            apiFactoryProvider: apiFactoryProvider
        ) else {
            return.failure(.hasNoSession)
        }
        return .success(session)
    }
    
    public func login(credentials: Credentials) async -> Result<ActiveSession, LoginError> {
        let method = Auth.Login(
            credentials: CredentialsDto(
                email: credentials.email,
                password: credentials.password
            )
        )
        let apiError: ApiError
        switch await api.run(method: method) {
        case .success(let token):
            do {
                return .success(
                    try await ActiveSession.awake(
                        anonymousApi: api,
                        hostId: token.id,
                        accessToken: token.accessToken,
                        refreshToken: token.refreshToken,
                        apiServiceFactory: apiServiceFactory,
                        persistencyFactory: persistencyFactory, 
                        apiFactoryProvider: apiFactoryProvider
                    )
                )
            } catch {
                return .failure(.other(error))
            }
        case .failure(let error):
            apiError = error
        }
        let errorCode: ApiErrorCode
        switch apiError {
        case .api(let code, _):
            errorCode = code
        case .noConnection(let error):
            return .failure(.noConnection(error))
        case .internalError(let error):
            return .failure(.other(error))
        }
        switch errorCode {
        case .incorrectCredentials:
            return .failure(.incorrectCredentials(apiError))
        case .wrongCredentialsFormat:
            return .failure(.wrongFormat(apiError))
        default:
            return .failure(.other(apiError))
        }
    }
    
    public func signup(credentials: Credentials) async -> Result<ActiveSession, SignupError> {
        let method = Auth.Signup(
            credentials: CredentialsDto(
                email: credentials.email,
                password: credentials.password
            )
        )
        let apiError: ApiError
        switch await api.run(method: method) {
        case .success(let token):
            do {
                return .success(
                    try await ActiveSession.awake(
                        anonymousApi: api,
                        hostId: token.id,
                        accessToken: token.accessToken,
                        refreshToken: token.refreshToken,
                        apiServiceFactory: apiServiceFactory,
                        persistencyFactory: persistencyFactory, 
                        apiFactoryProvider: apiFactoryProvider
                    )
                )
            } catch {
                return .failure(.other(error))
            }
        case .failure(let error):
            apiError = error
        }
        let errorCode: ApiErrorCode
        switch apiError {
        case .api(let code, _):
            errorCode = code
        case .noConnection(let error):
            return .failure(.noConnection(error))
        case .internalError(let error):
            return .failure(.other(error))
        }
        switch errorCode {
        case .loginAlreadyTaken:
            return .failure(.alreadyTaken(apiError))
        case .wrongCredentialsFormat:
            return .failure(.wrongFormat(apiError))
        default:
            return .failure(.other(apiError))
        }
    }
}
