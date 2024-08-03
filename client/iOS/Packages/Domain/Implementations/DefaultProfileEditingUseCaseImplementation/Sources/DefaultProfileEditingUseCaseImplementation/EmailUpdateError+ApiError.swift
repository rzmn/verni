import Domain
import Api

extension EmailUpdateError {
    init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .other(.noConnection(error))
        case .internalError(let error):
            self = .other(.other(error))
        case .api(let errorCode, _):
            switch errorCode {
            case .loginAlreadyTaken:
                self = .validationError(.alreadyTaken)
            case .wrongCredentialsFormat:
                self = .validationError(.invalidFormat)
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
