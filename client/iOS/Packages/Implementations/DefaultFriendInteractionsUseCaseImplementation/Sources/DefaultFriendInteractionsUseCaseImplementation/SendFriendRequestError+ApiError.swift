import Domain
import Api
internal import ApiDomainConvenience

extension SendFriendRequestError {
    init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .other(.noConnection(error))
        case .internalError(let error):
            self = .other(.other(error))
        case .api(let errorCode, _):
            switch errorCode {
            case .alreadySend:
                self = .alreadySent(apiError)
            case .haveIncomingRequest:
                self = .haveIncoming(apiError)
            case .alreadyFriends:
                self = .alreadyFriends(apiError)
            case .noSuchUser:
                self = .noSuchUser(apiError)
            default:
                self = .other(GeneralError(apiError: apiError))
            }
        }
    }
}
