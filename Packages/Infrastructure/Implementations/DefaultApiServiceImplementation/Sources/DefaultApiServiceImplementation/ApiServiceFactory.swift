import ApiService
import Networking
import Logging
import Base

public actor DefaultApiServiceFactory {
    private let logger: Logger
    private let networkServiceFactory: NetworkServiceFactory
    private let taskFactory: TaskFactory

    public init(
        logger: Logger,
        networkServiceFactory: NetworkServiceFactory,
        taskFactory: TaskFactory
    ) {
        self.logger = logger
        self.networkServiceFactory = networkServiceFactory
        self.taskFactory = taskFactory
    }
}

extension DefaultApiServiceFactory: ApiServiceFactory {
    public func create(
        tokenRefresher: (any TokenRefresher)?
    ) async -> any ApiService {
        DefaultApiService(
            logger: logger,
            networkServiceFactory: networkServiceFactory,
            taskFactory: taskFactory,
            tokenRefresher: tokenRefresher
        )
    }
}
