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
                self = .alreadyTaken
            case .wrongCredentialsFormat:
                self = .wrongFormat
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
