import Domain
import Api

extension SignupError {
    init(apiError: ApiError) {
        switch apiError {
        case .api(let errorCode, _):
            switch errorCode {
            case .loginAlreadyTaken:
                self = .alreadyTaken(apiError)
            case .wrongCredentialsFormat:
                self = .wrongFormat(apiError)
            default:
                self = .other(apiError)
            }
        case .noConnection(let error):
            self = .noConnection(error)
        case .internalError(let error):
            self = .other(error)
        }
    }
}
