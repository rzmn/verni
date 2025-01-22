import Entities
import Api
import AuthUseCase
internal import Convenience

extension LoginError {
    init(_ apiError: Components.Schemas._Error) {
        switch apiError.reason {
        case .incorrectCredentials:
            self = .incorrectCredentials(ErrorContext(context: apiError))
        case .wrongFormat:
            self = .wrongFormat(ErrorContext(context: apiError))
        default:
            self = .other(ErrorContext(context: apiError))
        }
    }

    init(_ error: Error) {
        if let error = error.noConnection {
            self = .noConnection(error)
        } else {
            self = .other(error)
        }
    }
}
