import Domain
import Api

extension PasswordUpdateError {
    init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .other(.noConnection(error))
        case .internalError(let error):
            self = .other(.other(error))
        case .api(let errorCode, _):
            switch errorCode {
            case .incorrectCredentials:
                self = .incorrectOldPassword
            case .wrongCredentialsFormat:
                self = .validationError(.invalidFormat)
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
