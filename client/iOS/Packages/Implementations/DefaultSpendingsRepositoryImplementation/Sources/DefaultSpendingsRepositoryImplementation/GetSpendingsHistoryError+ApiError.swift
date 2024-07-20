import Api
import Domain
internal import ApiDomainConvenience

extension GetSpendingsHistoryError {
    init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .other(.noConnection(error))
        case .internalError(let error):
            self = .other(.other(error))
        case .api(let errorCode, _):
            switch errorCode {
            case .noSuchUser:
                self = .noSuchCounterparty(apiError)
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
