import Testing
import Networking
@testable import DefaultNetworkingImplementation

@Suite struct ExponentialBackoffTests {
    @Test func testRetryCount() {

        // given

        let retryCount = 0
        let maxRetryCount = 10
        let backoff = ExponentialBackoff(base: 0.15, retryCount: retryCount, maxRetryCount: maxRetryCount)

        // when

        let expectedRetries = maxRetryCount - retryCount
        let retries = sequence(first: backoff, next: { backoff in
            let next = backoff.nextRetry()
            guard next.shouldTryAgain else {
                return nil
            }
            return next
        })

        // then

        #expect(Array(retries).count == expectedRetries)
    }

    @Test func testRetryWaitTimeIsGrowing() {

        // given

        let retryCount = 0
        let maxRetryCount = 10
        let backoff = ExponentialBackoff(base: 0.15, retryCount: retryCount, maxRetryCount: maxRetryCount)

        // when

        let retries = sequence(first: backoff, next: { backoff in
            let next = backoff.nextRetry()
            guard next.shouldTryAgain else {
                return nil
            }
            return next
        })

        // then

        #expect(
            zip(retries, retries.dropFirst()).allSatisfy { current, next in
                current.waitTimeInterval < next.waitTimeInterval
            }
        )
    }
}
