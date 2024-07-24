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

public enum ApiResult<T> {
    case success(T)
    case failure(ApiError)

    func map<R>(_ block: (T) -> R) -> ApiResult<R> {
        switch self {
        case .success(let t):
            return .success(block(t))
        case .failure(let apiError):
            return .failure(apiError)
        }
    }

}
