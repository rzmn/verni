import Networking
import Logging

public class DefaultNetworkServiceFactory {
    private let logger: Logger
    private let endpoint: Endpoint

    public init(logger: Logger, endpoint: Endpoint) {
        self.logger = logger
        self.endpoint = endpoint
    }
}

extension DefaultNetworkServiceFactory: NetworkServiceFactory {
    public func create() -> NetworkService {
        Service(logger: logger, endpoint: endpoint)
    }
}
