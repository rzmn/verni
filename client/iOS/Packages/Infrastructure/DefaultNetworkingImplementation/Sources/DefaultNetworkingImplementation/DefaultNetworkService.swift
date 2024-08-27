import Foundation
import Networking
import Logging
internal import Base

public struct Endpoint {
    public let path: String

    public init(path: String) {
        self.path = path
    }
}

extension Endpoint: CompactDescription {}

class DefaultNetworkService {
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

        logI { "initialized network service. endpoint: \(endpoint)" }
    }
}

extension DefaultNetworkService: NetworkService {
    func run<T>(_ request: T) async -> Result<NetworkServiceResponse, NetworkServiceError> where T: NetworkRequest {
        logI { "starting request \(request)" }
        let url: URL
        switch await UrlBuilder(
            endpoint: endpoint, 
            request: request,
            logger: logger.with(prefix: "[\(request.path)] ")
        ).build() {
        case .success(let result):
            url = result
        case .failure(let error):
            return .failure(error)
        }
        let urlRequest: URLRequest
        switch await UrlRequestBuilder(
            url: url,
            request: request,
            encoder: encoder,
            logger: logger.with(prefix: "[\(url)] ")
        ).build() {
        case .success(let request):
            urlRequest = request
        case .failure(let error):
            return .failure(error)
        }
        logI { "\(request.path): built request: \(urlRequest)" }
        return await RequestRunner(
            session: session,
            request: urlRequest,
            logger: logger.with(prefix: "[\(url)] ")
        ).run()
    }
}

extension DefaultNetworkService: Loggable {}
