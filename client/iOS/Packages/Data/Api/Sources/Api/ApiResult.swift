import Foundation

public enum ApiResult<T> {
    case success(T)
    case failure(ApiError)

    public func map<R>(_ block: (T) -> R) -> ApiResult<R> {
        switch self {
        case .success(let t):
            return .success(block(t))
        case .failure(let apiError):
            return .failure(apiError)
        }
    }
}
