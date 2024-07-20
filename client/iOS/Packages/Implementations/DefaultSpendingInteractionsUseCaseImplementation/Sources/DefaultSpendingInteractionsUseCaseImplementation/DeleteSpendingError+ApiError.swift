import Domain
import Api

extension DeleteSpendingError {
    init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .other(.noConnection(error))
        case .internalError(let error):
            self = .other(.other(error))
        case .api(let errorCode, _):
            switch errorCode {
            case .dealNotFound:
                self = .noSuchSpending(apiError)
            case .isNotYourDeal, .notAFriend:
                self = .privacy(apiError)
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
