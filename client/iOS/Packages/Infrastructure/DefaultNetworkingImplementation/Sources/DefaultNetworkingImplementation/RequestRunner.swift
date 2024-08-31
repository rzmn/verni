import Foundation
import Networking
import Logging
internal import Base

fileprivate extension Error {
    var networkServiceError: NetworkServiceError {
        let error = self as NSError
        guard error.domain == NSURLErrorDomain else {
            return .cannotSend(error)
        }
        let noConnectionCodes: [URLError.Code] = [
            .networkConnectionLost,
            .timedOut,
            .notConnectedToInternet
        ]
        guard noConnectionCodes.map(\.rawValue).contains(error.code) else {
            return .cannotSend(error)
        }
        return .noConnection(error)
    }
}

fileprivate struct ExponentialBackoff: CompactDescription {
    let base: TimeInterval = 0.5
    let retryCount: Int
    let maxRetryCount: Int = 3

    var shouldTryAgain: Bool {
        retryCount < maxRetryCount
    }
}

struct RequestRunner: Loggable {
    private let session: URLSession
    private let request: URLRequest
    let logger: Logger

    init(session: URLSession, request: URLRequest, logger: Logger) {
        self.session = session
        self.request = request
        self.logger = logger
    }
}

extension RequestRunner {
    func run() async throws(NetworkServiceError) -> NetworkServiceResponse {
        try await run(backoff: ExponentialBackoff(retryCount: 0))
    }

    private func run(
        backoff: ExponentialBackoff
    ) async throws(NetworkServiceError) -> NetworkServiceResponse {
        logI { "run request \(request) backoff \(backoff)" }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
            logD { "got JSON: \(String(data: data, encoding: .utf8) ?? "nil")" }
        } catch {
            let serviceError = error.networkServiceError
            logE { "failed to run data task error: \(error)" }
            if backoff.shouldTryAgain {
                logI { "backoff try \(backoff.retryCount)" }
                do {
                    try await Task.sleep(for: .milliseconds(Int(backoff.base * pow(2, Double(backoff.retryCount)) * 1000)))
                    return try await run(backoff: ExponentialBackoff(retryCount: backoff.retryCount + 1))
                } catch {
                    logI { "backoff failed on try \(backoff.retryCount) error: \(error)" }
                    throw serviceError
                }
            } else {
                logI { "stopping backoff error: \(error)" }
                throw serviceError
            }
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            logE { "response is not an HTTPURLResponse. found: \(response)" }
            throw .badResponse(InternalError.error("bad respose type: \(response)", underlying: nil))
        }
        let code = HttpCode(
            code: httpResponse.statusCode
        )
        if case .serverError = code {
            if backoff.shouldTryAgain {
                do {
                    try await Task.sleep(for: .milliseconds(Int(backoff.base * pow(2, Double(backoff.retryCount)) * 1000)))
                    return try await run(backoff: ExponentialBackoff(retryCount: backoff.retryCount + 1))
                } catch {
                    return NetworkServiceResponse(
                        code: code,
                        data: data
                    )
                }
            }
        }
        logI { "got http response" }
        return NetworkServiceResponse(
            code: code,
            data: data
        )
    }
}
