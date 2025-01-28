import Domain
import Api
import Base

extension LoginError {
    public init(_ apiError: ApiErrorConvertible) {
        switch apiError.apiError.reason {
        case .incorrectCredentials:
            self = .incorrectCredentials(ErrorContext(context: apiError))
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
