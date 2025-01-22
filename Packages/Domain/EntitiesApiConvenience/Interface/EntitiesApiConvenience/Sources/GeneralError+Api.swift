import Entities
import Api
internal import Convenience

extension GeneralError {
    public init(error: Components.Schemas._Error) {
        switch error.reason {
        case .tokenExpired:
            self = .notAuthorized(ErrorContext(context: error))
        default:
            self = .other(ErrorContext(context: error))
        }
    }
    
    public init(error: Error) {
        if let noConnection = error.noConnection {
            self = .noConnection(noConnection)
        } else {
            self = .other(error)
        }
    }
}
