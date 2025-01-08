import Domain
import Api
import Base
import Foundation

extension GeneralError {
    public init(_ apiError: ApiErrorConvertible) {
        switch apiError.apiError.reason {
        case .tokenExpired:
            self = .notAuthorized(ErrorContext(context: apiError))
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
