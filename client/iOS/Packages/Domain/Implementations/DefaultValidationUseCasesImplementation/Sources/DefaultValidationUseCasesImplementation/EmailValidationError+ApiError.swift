import Domain
import Api
internal import ApiDomainConvenience

extension EmailValidationError {
    init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .other(.noConnection(error))
        case .internalError(let error):
            self = .other(.other(error))
        case .api(let errorCode, _):
            switch errorCode {
            case .loginAlreadyTaken:
                self = .alreadyTaken
            case .wrongCredentialsFormat:
                self = .invalidFormat
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
