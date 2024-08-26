import Api
import Domain
internal import ApiDomainConvenience

extension GetSpendingError {
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
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
