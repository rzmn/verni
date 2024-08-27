import Networking
import Logging
import Foundation

public class DefaultNetworkServiceFactory {
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
