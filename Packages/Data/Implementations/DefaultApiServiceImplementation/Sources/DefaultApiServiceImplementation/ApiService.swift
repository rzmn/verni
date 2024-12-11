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
                    logger: logger,
                    service: networkServiceFactory.create()
                ),
                taskFactory: taskFactory,
                tokenRefresher: tokenRefresher
            ),
            taskFactory: taskFactory
        )
        logI { "created api, authorized=\(tokenRefresher != nil ? "true" : "false")" }
    }
}

extension DefaultApiService: ApiService {
    public func run<Response: Decodable & Sendable>(
        request: some ApiServiceRequest
    ) async throws(ApiServiceError) -> Response {
        try await runner.run(request: request)
    }
}

extension DefaultApiService: Loggable {}
