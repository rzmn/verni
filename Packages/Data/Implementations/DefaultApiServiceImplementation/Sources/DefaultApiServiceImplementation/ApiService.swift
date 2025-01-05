import Networking
import Logging
import ApiService
import Foundation
import Base
import AsyncExtensions

actor DefaultApiService {
    let logger: Logger
    private let runner: MaxSimultaneousRequestsRestrictor

    public init(
        logger: Logger,
        networkServiceFactory: NetworkServiceFactory,
        taskFactory: TaskFactory,
        tokenRefresher: TokenRefresher?
    ) {
        self.logger = logger
        runner = MaxSimultaneousRequestsRestrictor(
            limit: 5,
            manager: ApiServiceRequestRunnersManager(
                runnerFactory: DefaultApiServiceRequestRunnerFactory(
                    logger: logger.with(prefix: "💡"),
                    service: networkServiceFactory.create()
                ),
                taskFactory: taskFactory,
                logger: logger.with(prefix: "🚥"),
                tokenRefresher: tokenRefresher
            ),
            taskFactory: taskFactory
        )
        logI { "created api, authorized=\(tokenRefresher != nil ? "true" : "false")" }
    }
}

extension DefaultApiService: ApiService {
    public func run(
        request: some ApiServiceRequest
    ) async throws(ApiServiceError) -> Data {
        try await runner.run(request: request)
    }
}

extension DefaultApiService: Loggable {}
