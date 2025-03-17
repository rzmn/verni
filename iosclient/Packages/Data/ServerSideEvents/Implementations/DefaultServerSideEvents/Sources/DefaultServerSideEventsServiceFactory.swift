import Api
import ServerSideEvents
import Logging
import Foundation
import AsyncExtensions

public final class DefaultServerSideEventsServiceFactory: Sendable {
    private let taskFactory: TaskFactory
    private let logger: Logger
    private let endpoint: URL
    
    public init(
        taskFactory: TaskFactory,
        logger: Logger,
        endpoint: URL
    ) {
        self.taskFactory = taskFactory
        self.logger = logger
        self.endpoint = endpoint
    }
}

extension DefaultServerSideEventsServiceFactory: ServerSideEventsServiceFactory {
    public func create(refreshTokenMiddleware: AuthMiddleware?) -> RemoteUpdatesService {
        ServerSideEventsService(
            taskFactory: taskFactory,
            logger: logger.with(
                prefix: "[session]"
            ),
            urlConfigurationFactory: { [endpoint] in
                DefaultUrlConfiguration(
                    endpoint: endpoint.appendingPathComponent("/operationsQueue")
                )
            },
            chunkCollectorFactory: { [logger] in
                DefaultChunkCollector(
                    logger: logger.with(
                        prefix: "[chunks]"
                    )
                )
            },
            eventParserFactory: { [logger] in
                DefaultEventParser(
                    logger: logger.with(
                        prefix: "[parser]"
                    )
                )
            },
            refreshTokenMiddleware: refreshTokenMiddleware
        )
    }
}
