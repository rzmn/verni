import OpenAPIRuntime
import HTTPTypes
import Logging
import Foundation
import AsyncExtensions

struct RetryingMiddleware {
    enum RetryableSignal: Hashable {
        case code(Int)
        case range(Range<Int>)
        case errorThrown
    }

    enum RetryingPolicy: Hashable {
        case upToAttempts(count: Int)
    }

    enum DelayPolicy: Hashable {
        /// `interval * (base ^ attempt)`
        case exponential(
            interval: TimeInterval,
            attempt: Int,
            base: Double
        )
    }
    let logger: Logger
    let signals: Set<RetryableSignal>
    let policy: RetryingPolicy
    let delay: DelayPolicy
    let taskFactory: TaskFactory

    init(
        logger: Logger,
        taskFactory: TaskFactory,
        signals: Set<RetryableSignal>,
        policy: RetryingPolicy,
        delay: DelayPolicy
    ) {
        self.logger = logger
        self.taskFactory = taskFactory
        self.signals = signals
        self.policy = policy
        self.delay = delay
    }
}

extension RetryingMiddleware: ClientMiddleware {
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        guard case .upToAttempts(count: let maxAttemptCount) = policy else {
            return try await next(request, body, baseURL)
        }
        if let body {
            guard body.iterationBehavior == .multiple else {
                logI { "body of request \(operationID) has single iteration behaviour" }
                return try await next(request, body, baseURL)
            }
        }
        func willRetry() async throws {
            switch delay {
            case .exponential(let interval, let attempt, let base):
                try await Task.sleep(timeInterval: interval * pow(base, Double(attempt)))
            }
        }
        for attempt in 0 ..< maxAttemptCount {
            logI { "attempt \(attempt)" }
            let (response, responseBody): (HTTPResponse, HTTPBody?)
            if signals.contains(.errorThrown) {
                do {
                    (response, responseBody) = try await next(request, body, baseURL)
                } catch {
                    if attempt == maxAttemptCount {
                        throw error
                    } else {
                        logI { "retrying after an error" }
                        try await willRetry()
                        continue
                    }
                }
            } else {
                (response, responseBody) = try await next(request, body, baseURL)
            }
            if signals.contains(response.status.code) && attempt < maxAttemptCount {
                logI { "retrying with code \(response.status.code)" }
                try await willRetry()
                continue
            } else {
                logI { "returning the received response, either because of success or ran out of attempts." }
                return (response, responseBody)
            }
        }
        preconditionFailure("unreachable")
    }
}

extension Set where Element == RetryingMiddleware.RetryableSignal {
    func contains(_ code: Int) -> Bool {
        for signal in self {
            switch signal {
            case .code(let int) where code == int:
                return true
            case .range(let range) where range.contains(code):
                return true
            default:
                break
            }
        }
        return false
    }
}

extension RetryingMiddleware: Loggable {}
