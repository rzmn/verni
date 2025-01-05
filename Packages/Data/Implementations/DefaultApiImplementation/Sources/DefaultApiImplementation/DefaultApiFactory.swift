import Api
import ApiService
import Base
import AsyncExtensions
import Logging
import OpenAPIRuntime

public final class DefaultApiFactory: Sendable {
    private let refresher: TokenRefresher?
    private let impl: DefaultApi
    private let taskFactory: TaskFactory
    private let logger: Logger

    public init(
        taskFactory: TaskFactory,
        logger: Logger,
        tokenRefresher: TokenRefresher?
    ) {
        self.refresher = tokenRefresher
        self.logger = logger.with(prefix: "🚀")
        self.taskFactory = taskFactory
        self.impl = DefaultApi(service: service)
    }
}

extension DefaultApiFactory: ApiFactory {
    public func create() -> APIProtocol {
        Client(
            serverURL: <#T##URL#>,
            transport: <#T##any ClientTransport#>,
            middlewares: [
                refresher.flatMap { refresher in
                    RefreshTokenMiddleware(
                        refresher: refresher,
                        taskFactory: taskFactory,
                        logger: logger
                    )
                },
                RetryingMiddleware(
                    logger: logger,
                    taskFactory: taskFactory,
                    signals: Set([
                        .code(429),
                        .range(500 ..< 600),
                        .errorThrown
                    ]),
                    policy: .upToAttempts(
                        count: 4
                    ),
                    delay: .exponential(
                        interval: 1,
                        attempt: 0,
                        base: 2
                    )
                )
            ].compactMap { $0 }
        )
    }

    public func longPoll() -> any LongPoll {
        DefaultLongPoll(api: impl, taskFactory: taskFactory, logger: logger)
    }
}
