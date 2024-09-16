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
                    service: networkServiceFactory.create()
                ),
                taskFactory: taskFactory,
                tokenRefresher: tokenRefresher
            ),
            taskFactory: taskFactory
        )
        logI { "initialized network service. has token refresher: \(tokenRefresher != nil)" }
    }
}

extension DefaultApiService: ApiService {
    public func run<Request: ApiServiceRequest, Response: Decodable & Sendable>(
        request: Request
    ) async throws(ApiServiceError) -> Response {
        try await runner.run(request: request)
    }
}

extension DefaultApiService: Loggable {}
