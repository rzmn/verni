import Domain
import Api
import ApiService
import AuthSession

public class DefaultAuthUseCase {
    private let api: Api
    private let apiServiceFactory: ApiServiceFactory

    public init(api: Api, apiServiceFactory: ApiServiceFactory) {
        self.api = api
        self.apiServiceFactory = apiServiceFactory
    }
}

extension DefaultAuthUseCase: AuthUseCase {
    public func awake() async -> Result<ActiveSession, AwakeError> {
        guard let session = await ActiveSession.awake(anonymousApi: api, factory: apiServiceFactory) else {
            return.failure(.hasNoSession)
        }
        return .success(session)
    }
    
    public func login(credentials: Credentials) async -> Result<ActiveSession, LoginError> {
        let apiError: ApiError
        switch await api.login(credentials: CredentialsDto(login: credentials.login, password: credentials.password)) {
        case .success(let token):
            return .success(
                await ActiveSession.awake(
                    anonymousApi: api,
                    accessToken: token.accessToken,
                    refreshToken: token.refreshToken,
                    factory: apiServiceFactory
                )
            )
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
        let apiError: ApiError
        switch await api.signup(credentials: CredentialsDto(login: credentials.login, password: credentials.password)) {
        case .success(let token):
            return .success(
                await ActiveSession.awake(
                    anonymousApi: api,
                    accessToken: token.accessToken,
                    refreshToken: token.refreshToken,
                    factory: apiServiceFactory
                )
            )
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
    
    public func validateLogin(_ login: String) async -> Result<Void, CredentialsValidationError> {
        let minAllowedLength = 4
        guard login.count >= minAllowedLength else {
            return .failure(.tooShort(minAllowedLength: minAllowedLength))
        }
        return .success(())
    }

    public func validatePassword(_ password: String) async -> Result<Void, CredentialsValidationError> {
        let minAllowedLength = 5
        guard password.count >= minAllowedLength else {
            return .failure(.tooShort(minAllowedLength: minAllowedLength))
        }
        return .success(())
    }
}
