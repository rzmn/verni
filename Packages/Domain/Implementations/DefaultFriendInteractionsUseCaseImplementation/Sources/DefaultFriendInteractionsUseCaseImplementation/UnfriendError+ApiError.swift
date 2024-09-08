import Domain
import Api
internal import ApiDomainConvenience

extension UnfriendError {
    init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .other(.noConnection(error))
        case .internalError(let error):
            self = .other(.other(error))
        case .api(let code, _):
            switch code {
            case .notAFriend:
                self = .notAFriend(apiError)
            case .noSuchUser:
                self = .noSuchUser(apiError)
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
