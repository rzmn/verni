import Api
import ServerSideEvents
import Convenience
import AsyncExtensions
import Logging
import Foundation

extension SessionStartError: AuthMiddlewareError {
    var isTokenExpired: Bool {
        guard case .tokenExpired = self else {
            return true
        }
        return false
    }
}

actor ServerSideEventsService {
    private let publisher: EventPublisher<RemoteUpdate>
    
    let logger: Logger
    private let taskFactory: TaskFactory
    private let urlConfigurationFactory: @Sendable () -> UrlConfiguration
    private let chunkCollectorFactory: @Sendable () -> ChunkCollector
    private let eventParserFactory: @Sendable () -> EventParser
    
    private let refreshTokenMiddleware: AuthMiddleware?
    
    private var currentSession: ServerSideEventsSession?
    private var eventLoop: Task<Void, Never>?
    
    init(
        taskFactory: TaskFactory,
        logger: Logger,
        urlConfigurationFactory: @escaping @Sendable () -> UrlConfiguration,
        chunkCollectorFactory: @escaping @Sendable () -> ChunkCollector,
        eventParserFactory: @escaping @Sendable () -> EventParser,
        refreshTokenMiddleware: AuthMiddleware?
    ) {
        self.logger = logger
        self.taskFactory = taskFactory
        self.publisher = EventPublisher()
        self.refreshTokenMiddleware = refreshTokenMiddleware
        self.urlConfigurationFactory = urlConfigurationFactory
        self.chunkCollectorFactory = chunkCollectorFactory
        self.eventParserFactory = eventParserFactory
    }
}

extension ServerSideEventsService: RemoteUpdatesService {
    var eventSource: any EventSource<RemoteUpdate> {
        publisher
    }
    
    func start() {
        logI { "starting SSE service" }
        guard eventLoop == nil else {
            return
        }
        eventLoop = Task {
            await eventLoop()
        }
    }
    
    func stop() async {
        logI { "stopping SSE service" }
        eventLoop?.cancel()
        eventLoop = nil
        
        await currentSession?.stop()
        currentSession = nil
        
    }
    
    private func eventLoop() async {
        guard let refreshTokenMiddleware else {
            return logI { "does not support sse without user session" }
        }
        let retryInterval: TimeInterval = 5
        repeat {
            if Task.isCancelled {
                return
            }
            logI { "starting sse event loop iteration" }
            let stream = AsyncStream<RemoteUpdate>.makeStream()
            let eventListener = Task {
                for await event in stream.stream {
                    if Task.isCancelled {
                        return
                    }
                    await publisher.notify(event)
                }
            }
            let urlConfiguration = urlConfigurationFactory()
            let session = DefaultServerSideEventsSession(
                logger: logger,
                urlConfiguration: urlConfiguration,
                stream: stream,
                chunkCollectorFactory: chunkCollectorFactory,
                eventParserFactory: eventParserFactory
            )
            currentSession = session
            do {
                try await refreshTokenMiddleware.intercept { authHeaderValue async -> Result<Void, SessionStartError> in
                    await urlConfiguration.updateAuthHeaderValue(authHeaderValue)
                    return await session.start()
                }
            } catch {
                await session.stop()
                do {
                    if let error = error as? SessionStartError {
                        switch error {
                        case .tokenExpired:
                            logW { "unable to initialize sse session - access token expired" }
                            try await Task.sleep(timeInterval: retryInterval)
                        case .retriableError(let error):
                            logW { "unable to initialize sse session - will retry, error: \(error)" }
                            try await Task.sleep(timeInterval: retryInterval)
                        case .nonHttpResponse(let response):
                            return logE { "got non-http response: \(response)" }
                        case .nonRetriableError(let error):
                            return logE { "got non-retriable http error: \(error)" }
                        }
                    } else if let error = error.noConnection {
                        logI { "got no connection error on session initialize: \(error)" }
                        try await Task.sleep(timeInterval: retryInterval)
                    } else {
                        logE { "got api error on session initialize: \(error)" }
                        try await Task.sleep(timeInterval: retryInterval)
                    }
                } catch {
                    return logE { "failed to sleep a task error: \(error)" }
                }
                continue
            }
            await eventListener.value
        } while true
    }
}

extension ServerSideEventsService: Loggable {}
