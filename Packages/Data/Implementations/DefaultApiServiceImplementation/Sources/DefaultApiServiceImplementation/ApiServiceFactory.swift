import ApiService
import Networking
import Logging
import Base
import AsyncExtensions

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
    nonisolated public func create(
        tokenRefresher: (any TokenRefresher)?
    ) -> any ApiService {
        DefaultApiService(
            logger: logger,
            networkServiceFactory: networkServiceFactory,
            taskFactory: taskFactory,
            tokenRefresher: tokenRefresher
        )
    }
}
