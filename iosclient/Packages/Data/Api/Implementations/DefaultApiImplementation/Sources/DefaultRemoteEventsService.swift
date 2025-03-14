import Api
import Foundation
import Convenience
import AsyncExtensions
import Logging

public actor DefaultRemoteEventsService {
    private let taskFactory: TaskFactory
    private let logger: Logger
    private let apiEndpoint: URL
    private let tokenRepository: RefreshTokenRepository?
    private var sse: SSEService?
    private let eventPublisher = EventPublisher<RemoteUpdate>()

    public init(
        taskFactory: TaskFactory,
        tokenRepository: RefreshTokenRepository?,
        logger: Logger,
        apiEndpoint: URL
    ) {
        self.taskFactory = taskFactory
        self.logger = logger
        self.apiEndpoint = apiEndpoint
        self.tokenRepository = tokenRepository
    }
}

extension DefaultRemoteEventsService: RemoteUpdatesService {
    public var eventSource: any EventSource<RemoteUpdate> {
        get async {
            eventPublisher
        }
    }
    
    public func start() async {
        let sseService: SSEService
        if let sse {
            sseService = sse
        } else {
            sseService = await {
                let service = await SSEService(
                    taskFactory: taskFactory,
                    logger: logger,
                    endpoint: apiEndpoint,
                    tokenRepository: tokenRepository
                )
                await service.eventSource.subscribeWeak(self) { [taskFactory, eventPublisher] event in
                    taskFactory.task {
                        await eventPublisher.notify(event)
                    }
                }
                return service
            }()
        }
        await sseService.start()
    }
    
    public func stop() async {
        await sse?.stop()
    }
}
