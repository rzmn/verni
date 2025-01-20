import Entities
import Api
import Base

extension SignupError {
    public init(_ apiError: ApiErrorConvertible) {
        switch apiError.apiError.reason {
        case .alreadyTaken:
            self = .alreadyTaken(ErrorContext(context: apiError))
        case .wrongFormat:
            self = .wrongFormat(ErrorContext(context: apiError))
        default:
            self = .other(ErrorContext(context: apiError))
        }
    }

    public init(_ error: Error) {
        if let error = error.noConnection {
            self = .noConnection(error)
        } else {
            self = .other(error)
        }
    }
}
