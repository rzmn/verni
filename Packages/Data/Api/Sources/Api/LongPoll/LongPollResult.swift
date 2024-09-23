import Foundation

public enum LongPollResult<Success> {
    case success(Success)
    case failure(LongPollError)

    public func map<R>(_ block: (Success) -> R) -> LongPollResult<R> {
        switch self {
        case .success(let success):
            return .success(block(success))
        case .failure(let apiError):
            return .failure(apiError)
        }
    }
}
