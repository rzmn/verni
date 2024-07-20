import Domain
import Api

extension CreateSpendingError {
    init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .other(.noConnection(error))
        case .internalError(let error):
            self = .other(.other(error))
        case .api(let errorCode, _):
            switch errorCode {
            case .noSuchUser:
                self = .noSuchUser(apiError)
            case .notAFriend:
                self = .privacy(apiError)
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
