import Foundation
internal import Base

struct ExponentialBackoff: CompactDescription, Sendable {
    let base: TimeInterval
    let retryCount: Int
    let maxRetryCount: Int

    init(base: TimeInterval, retryCount: Int, maxRetryCount: Int) {
        self.base = base
        self.retryCount = retryCount
        self.maxRetryCount = maxRetryCount
    }

    var shouldTryAgain: Bool {
        retryCount < maxRetryCount
    }

    func nextRetry() -> Self {
        ExponentialBackoff(base: base, retryCount: retryCount + 1, maxRetryCount: maxRetryCount)
    }
}
