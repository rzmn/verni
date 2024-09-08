import Networking
import Logging
import Foundation

final public class DefaultNetworkServiceFactory: Sendable {
    private let logger: Logger
    private let session: URLSession
    private let endpoint: Endpoint

    public init(logger: Logger, session: URLSession, endpoint: Endpoint) {
        self.logger = logger
        self.session = session
        self.endpoint = endpoint
    }
}

extension DefaultNetworkServiceFactory: NetworkServiceFactory {
    public func create() -> NetworkService {
        DefaultNetworkService(logger: logger, endpoint: endpoint, session: session)
    }
}
