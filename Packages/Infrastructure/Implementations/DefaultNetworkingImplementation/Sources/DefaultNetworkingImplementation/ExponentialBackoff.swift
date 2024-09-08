import Foundation
internal import Base

struct ExponentialBackoff: CompactDescription, Sendable {
    private let base: TimeInterval
    private let retryCount: Int
    private let maxRetryCount: Int
    private let multiplier: Double

    init(base: TimeInterval, multiplier: Double = 2, retryCount: Int, maxRetryCount: Int) {
        self.base = base
        self.retryCount = retryCount
        self.maxRetryCount = maxRetryCount
        self.multiplier = multiplier
    }

    var shouldTryAgain: Bool {
        retryCount < maxRetryCount
    }

    var waitTimeInterval: TimeInterval {
        base * pow(multiplier, Double(retryCount))
    }

    func nextRetry() -> Self {
        ExponentialBackoff(base: base, retryCount: retryCount + 1, maxRetryCount: maxRetryCount)
    }
}
