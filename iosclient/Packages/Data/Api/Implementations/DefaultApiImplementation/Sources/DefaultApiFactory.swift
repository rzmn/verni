import Api
import Convenience
import AsyncExtensions
import Logging
import Foundation
internal import OpenAPIURLSession

public final class DefaultApiFactory: Sendable {
    private let tokenRepository: RefreshTokenRepository?
    private let taskFactory: TaskFactory
    private let logger: Logger
    private let url: URL
    
    public init(
        url: URL,
        taskFactory: TaskFactory,
        logger: Logger,
        tokenRepository: RefreshTokenRepository?
    ) {
        self.tokenRepository = tokenRepository
        self.logger = logger
        self.taskFactory = taskFactory
        self.url = url
    }
}

extension DefaultApiFactory: ApiFactory {
    public func create() -> any APIProtocol {
        Client(
            serverURL: url,
            transport: URLSessionTransport(),
            middlewares: [
                tokenRepository.flatMap { tokenRepository in
                    RefreshTokenMiddleware(
                        tokenRepository: tokenRepository,
                        taskFactory: taskFactory,
                        logger: logger
                            .with(prefix: "🚥")
                    )
                },
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
    }
    
    public func remoteUpdates() -> RemoteUpdatesService {
        DefaultRemoteEventsService(
            taskFactory: taskFactory,
            tokenRepository: tokenRepository,
            logger: logger,
            apiEndpoint: url
        )
    }
}
