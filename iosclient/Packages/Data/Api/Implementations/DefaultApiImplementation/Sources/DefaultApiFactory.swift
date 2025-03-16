import Api
import Convenience
import AsyncExtensions
import Logging
import Foundation
import OpenAPIRuntime
internal import OpenAPIURLSession

public final class DefaultApiFactory: Sendable {
    private let refreshTokenMiddleware: RefreshTokenMiddleware?
    private let taskFactory: TaskFactory
    private let logger: Logger
    private let url: URL
    private let remoteUpdatesService: RemoteUpdatesService
    private let api: APIProtocol
    
    public init(
        url: URL,
        taskFactory: TaskFactory,
        logger: Logger,
        tokenRepository: RefreshTokenRepository?
    ) {
        self.refreshTokenMiddleware = tokenRepository.flatMap { tokenRepository in
            RefreshTokenMiddleware(
                tokenRepository: tokenRepository,
                taskFactory: taskFactory,
                logger: logger
                    .with(prefix: "🚥")
            )
        }
        self.logger = logger
        self.taskFactory = taskFactory
        self.url = url
        self.api = Client(
            serverURL: url,
            transport: URLSessionTransport(),
            middlewares: [
                refreshTokenMiddleware as ClientMiddleware?,
                RetryingMiddleware(
                    logger: logger
                        .with(prefix: "🔄"),
                    taskFactory: taskFactory,
                    signals: Set(
                        [
                            .code(429),
                            .range(500 ..< 600),
                            .errorThrown
                        ]
                    ),
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
        self.remoteUpdatesService = DefaultRemoteEventsService(
            taskFactory: taskFactory,
            refreshTokenMiddleware: refreshTokenMiddleware,
            logger: logger,
            apiEndpoint: url,
            api: api
        )
    }
}

extension DefaultApiFactory: ApiFactory {
    public func create() -> any APIProtocol {
        api
    }
    
    public func remoteUpdates() -> RemoteUpdatesService {
        remoteUpdatesService
    }
}
