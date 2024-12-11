import Foundation
import Networking
import Logging
internal import Base

final class DefaultNetworkService: Sendable {
    let logger: Logger
    private let endpoint: Endpoint
    private let encoder = JSONEncoder()
    private let session: URLSession

    init(
        logger: Logger,
        endpoint: Endpoint,
        session: URLSession
    ) {
        self.logger = logger
        self.endpoint = endpoint
        self.session = session
        logI { "api endpoint: \(endpoint.path)" }
    }
}

extension DefaultNetworkService: NetworkService {
    func run(_ request: some NetworkRequest) async throws(NetworkServiceError) -> NetworkServiceResponse {
        logI { "starting request \(request)" }
        let url = try UrlBuilder(
            endpoint: endpoint,
            request: request,
            logger: logger.with(prefix: "[\(request.path)] ")
        ).build()
        let urlRequest = try UrlRequestBuilder(
            url: url,
            request: request,
            encoder: UrlRequestBuilderBodyEncoder(
                encoder: encoder
            ),
            logger: logger.with(prefix: "⚒️")
        ).build()
        logI { "\(request.path): built request: \(urlRequest)" }
        return try await RequestRunner(
            session: session,
            request: urlRequest,
            logger: logger.with(prefix: "🏄"),
            backoff: ExponentialBackoff(
                base: 0.5,
                retryCount: 3,
                maxRetryCount: 0
            )
        ).run()
    }
}

extension DefaultNetworkService: Loggable {}
