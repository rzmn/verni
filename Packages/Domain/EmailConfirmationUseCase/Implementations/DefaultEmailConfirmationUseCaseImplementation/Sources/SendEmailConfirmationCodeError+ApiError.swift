import Domain
import Api

extension SendEmailConfirmationCodeError {
    init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .other(.noConnection(error))
        case .internalError(let error):
            self = .other(.other(error))
        case .api(let errorCode, _):
            switch errorCode {
            case .notDelivered:
                self = .notDelivered
            case .alreadyConfirmed:
                self = .alreadyConfirmed
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
