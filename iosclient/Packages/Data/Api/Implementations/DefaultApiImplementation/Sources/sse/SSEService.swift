import Api
import Convenience
import AsyncExtensions
import Logging
import Foundation

actor SSEService {
    private let publisher: EventPublisher<RemoteUpdate>
    private let url: URL
    
    let logger: Logger
    private let taskFactory: TaskFactory
    private let refreshTokenMiddleware: RefreshTokenMiddleware?
    
    private var currentSession: SSESession?
    private var eventLoop: Task<Void, Never>?
    
    init(
        taskFactory: TaskFactory,
        logger: Logger,
        endpoint: URL,
        refreshTokenMiddleware: RefreshTokenMiddleware?
    ) async {
        self.logger = logger.with(prefix: "[sse] ")
        self.taskFactory = taskFactory
        self.publisher = EventPublisher()
        self.refreshTokenMiddleware = refreshTokenMiddleware
        self.url = endpoint.appendingPathComponent("/operationsQueue")
    }
}

extension SSEService: RemoteUpdatesService {
    var eventSource: any EventSource<RemoteUpdate> {
        publisher
    }
    
    func start() async {
        logI { "starting SSE service" }
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
            var iterator = stream.stream.makeAsyncIterator()
            let eventListener = Task {
                while let event = await iterator.next() {
                    if Task.isCancelled {
                        return
                    }
                    await publisher.notify(event)
                }
            }
            typealias SessionInitResult = Result<SSESession, SSESession.InitializationFailureReason>
            let result: SessionInitResult?
            do {
                result = try await refreshTokenMiddleware.intercept { [logger, url] authHeaderValue in
                    let session = SSESession(
                        logger: logger,
                        authHeaderValue: authHeaderValue,
                        url: url,
                        stream: stream,
                        chunkCollectorFactory: { [logger] in
                            SSESession.DefaultChunkCollector(logger: logger)
                        },
                        eventParserFactory: { [logger] in
                            SSESession.DefaultEventParser(logger: logger)
                        }
                    )
                    switch await session.start() {
                    case .success:
                        return .success(.success(session))
                    case .failure(let reason):
                        switch reason {
                        case .nonHttpResponse, .nonRetriableHttpError:
                            return .success(.failure(reason))
                        case .tokenExpired:
                            return .failure(.unauthorized)
                        }
                    }
                }
            } catch {
                stream.continuation.finish()
                logE { "got api error on session initialize: \(error)" }
                do {
                    try await Task.sleep(timeInterval: retryInterval)
                    continue
                } catch {
                    return logE { "failed to sleep a task" }
                }
            }
            guard let result else {
                stream.continuation.finish()
                logW { "unable to initialize sse session - unable to get token" }
                do {
                    try await Task.sleep(timeInterval: retryInterval)
                    continue
                } catch {
                    return logE { "failed to sleep a task" }
                }
            }
            let session: SSESession
            do {
                session = try result.get()
            } catch {
                stream.continuation.finish()
                switch error {
                case .tokenExpired:
                    logW { "unable to initialize sse session - access token expired" }
                    do {
                        try await Task.sleep(timeInterval: retryInterval)
                        continue
                    } catch {
                        return logE { "failed to sleep a task" }
                    }
                case .nonHttpResponse(let response):
                    return logE { "got non-http response: \(response)" }
                case .nonRetriableHttpError(let error):
                    return logE { "got non-retriable http error: \(error)" }
                }
            }
            self.currentSession = session
            await eventListener.value
        } while true
    }
}

extension SSEService: Loggable {}
