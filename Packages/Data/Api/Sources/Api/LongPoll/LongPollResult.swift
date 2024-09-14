import Foundation

public enum LongPollResult<T> {
    case success(T)
    case failure(LongPollError)

    public func map<R>(_ block: (T) -> R) -> LongPollResult<R> {
        switch self {
        case .success(let t):
            return .success(block(t))
        case .failure(let apiError):
            return .failure(apiError)
        }
    }
}
