import Domain
import Api

extension GeneralError {
    public init(apiError: ApiError) {
        switch apiError {
        case .noConnection(let error):
            self = .noConnection(error)
        case .api(let code, _):
            switch code {
            case .tokenExpired:
                self = .notAuthorized(apiError)
            default:
                self = .other(apiError)
            }
        case .internalError(let error):
            self = .other(error)
        }
    }
}
