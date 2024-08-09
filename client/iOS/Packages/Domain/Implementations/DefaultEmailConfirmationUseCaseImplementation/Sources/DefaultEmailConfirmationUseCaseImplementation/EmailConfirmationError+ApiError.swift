import Domain
import Api

extension EmailConfirmationError {
    init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .other(.noConnection(error))
        case .internalError(let error):
            self = .other(.other(error))
        case .api(let errorCode, _):
            switch errorCode {
            case .incorrectCredentials:
                self = .codeIsWrong
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
