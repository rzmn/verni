import ApiService
import Networking
import Logging

public actor DefaultApiServiceFactory {
    private let logger: Logger
    private let networkServiceFactory: NetworkServiceFactory

    public init(
        logger: Logger,
        networkServiceFactory: NetworkServiceFactory
    ) {
        self.logger = logger
        self.networkServiceFactory = networkServiceFactory
    }
}

extension DefaultApiServiceFactory: ApiServiceFactory {
    public func create(tokenRefresher: (any TokenRefresher)?) async -> any ApiService {
        DefaultApiService(
            logger: logger,
            networkServiceFactory: networkServiceFactory,
            tokenRefresher: tokenRefresher
        )
    }
}
