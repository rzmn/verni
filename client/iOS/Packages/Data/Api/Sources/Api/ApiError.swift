import Foundation

public enum ApiError: Error, CustomStringConvertible {
    case api(ApiErrorCode, description: String?)
    case noConnection(Error)
    case internalError(Error)

    public var description: String {
        switch self {
        case .api(let apiErrorCode, let description):
            return "api: code \(apiErrorCode.rawValue) desc: \(description ?? "nil")"
        case .noConnection(let error):
            return "no connection: \(error)"
        case .internalError(let error):
            return "internal error: \(error)"
        }
    }
}
