import Foundation
import Networking
import Logging
internal import Base

struct RequestRunner: Loggable {
    private let session: URLSession
    private let request: URLRequest
    private let requestBackoff: ExponentialBackoff
    let logger: Logger

    init(
        session: URLSession,
        request: URLRequest,
        logger: Logger,
        backoff: ExponentialBackoff
    ) {
        self.session = session
        self.request = request
        self.logger = logger
        self.requestBackoff = backoff
    }
}

extension RequestRunner {
    func run() async throws(NetworkServiceError) -> NetworkServiceResponse {
        try await run(backoff: requestBackoff)
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
            if case .noConnection = serviceError, backoff.shouldTryAgain {
                logI { "backoff try \(backoff)" }
                do {
                    try await Task.sleep(timeInterval: backoff.waitTimeInterval)
                    return try await run(backoff: backoff.nextRetry())
                } catch {
                    logI { "backoff failed on try \(backoff) error: \(error)" }
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
                    try await Task.sleep(timeInterval: backoff.waitTimeInterval)
                    return try await run(backoff: backoff.nextRetry())
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
