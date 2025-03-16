import Api
import Convenience
import AsyncExtensions
import Logging
import Foundation

actor SSEService {
    private let publisher: EventPublisher<RemoteUpdate>
    private let url: URL
    private var task: Task<Void, Never>?
    
    private var urlSessionTask: URLSessionDataTask?
    
    let logger: Logger
    private let api: APIProtocol
    private let taskFactory: TaskFactory
    private let refreshTokenMiddleware: RefreshTokenMiddleware?
    
    init(
        taskFactory: TaskFactory,
        logger: Logger,
        endpoint: URL,
        refreshTokenMiddleware: RefreshTokenMiddleware?,
        api: APIProtocol
    ) async {
        self.logger = logger.with(prefix: "[sse] ")
        self.taskFactory = taskFactory
        self.publisher = EventPublisher()
        self.refreshTokenMiddleware = refreshTokenMiddleware
        self.url = endpoint.appendingPathComponent("/operationsQueue")
        self.api = api
    }
    
    private func acquireSession(refreshTokenMiddleware: RefreshTokenMiddleware) async throws(SSESession.TerminationReason) {
        urlSessionTask?.cancel()
        
        let delegate = SSEDataDelegate()
        let sseSession = SSESession(
            logger: logger,
            dataDelegate: delegate,
            publisher: publisher,
            chunkCollectorFactory: { [logger] in
                SSESession.DefaultChunkCollector(logger: logger)
            },
            eventParserFactory: { [logger] in
                SSESession.DefaultEventParser(logger: logger)
            }
        )
        
        typealias SSESessionTask = Task<Result<Void, SSESession.TerminationReason>, Never>
        let task: SSESessionTask?
        do {
            task = try await refreshTokenMiddleware
                .intercept { [weak self] authHeaderValue async -> Result<SSESessionTask, RefreshTokenMiddleware.RoutineFailure> in
                    guard let self else {
                        return .success(
                            Task {
                                .success(())
                            }
                        )
                    }
                    logD { "[debug] intercept routine start" }
                    defer {
                        logD { "[debug] intercept routine end" }
                    }
                    let urlSession = URLSession(
                        configuration: modify(URLSessionConfiguration.default) {
                            $0.timeoutIntervalForRequest = 600
                            $0.timeoutIntervalForResource = 3600
                            $0.httpMaximumConnectionsPerHost = 1
                            $0.requestCachePolicy = .reloadIgnoringLocalCacheData
                            $0.networkServiceType = .responsiveData
                            $0.shouldUseExtendedBackgroundIdleMode = true
                            $0.connectionProxyDictionary = [:]
                        },
                        delegate: delegate,
                        delegateQueue: modify(OperationQueue()) {
                            $0.name = "com.app.sse.delegate"
                            $0.maxConcurrentOperationCount = 1
                        }
                    )
                    await self.performIsolated { service in
                        service.urlSessionTask = urlSession.dataTask(
                            with: modify(URLRequest(url: url)) {
                                if let authHeaderValue {
                                    $0.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")
                                }
                                $0.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                                $0.setValue("text/event-stream", forHTTPHeaderField: "Content-Type")
                                $0.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                                $0.setValue("keep-alive", forHTTPHeaderField: "Connection")
                                $0.httpMethod = "GET"
                                $0.timeoutInterval = 600
                            }
                        )
                    }
                    await urlSessionTask?.resume()
                    let eventLoop = await sseSession.run()
                    switch eventLoop {
                    case .success(let task):
                        return .success(task)
                    case .failure(let reason):
                        switch reason {
                        case .tokenExpired:
                            logE { "unauthorized" }
                            return .failure(.unauthorized)
                        default:
                            logE { "sse session completed with error" }
                            return .success(
                                Task {
                                    .failure(.completedWithError(reason))
                                }
                            )
                        }
                    }
                }
        } catch {
            logE { "api error creating sse session: \(error)" }
            throw .completedWithError(error)
        }
        try await task?.value.get()
    }
    
    func stop() async {
        logI { "stopping SSE service" }
        task?.cancel()
        task = nil
        
        urlSessionTask?.cancel()
        urlSessionTask = nil
    }
}

extension SSEService: RemoteUpdatesService {
    var eventSource: any EventSource<RemoteUpdate> {
        publisher
    }
    
    func start() async {
        guard let refreshTokenMiddleware else {
            return logI { "does not support sse without user session" }
        }
        logI { "starting SSE service" }
        task = taskFactory.task { [weak self] in
            guard let self else { return }
            repeat {
                logD { "[debug] session manager iteration start" }
                defer {
                    logD { "[debug] session manager iteration end" }
                }
                if Task.isCancelled {
                    return
                }
                enum ReestablishmentPolicy {
                    case immediately
                    case failed
                    case afterDelay(TimeInterval)
                }
                func process() async -> ReestablishmentPolicy {
                    do {
                        try await acquireSession(refreshTokenMiddleware: refreshTokenMiddleware)
                        return .immediately
                    } catch {
                        switch error {
                        case .completedWithError:
                            return .afterDelay(5)
                        }
                    }
                }
                switch await process() {
                case .immediately:
                    logI { "reestablishing sse session" }
                    continue
                case .failed:
                    return logI { "finishing sse stream" }
                case .afterDelay(let interval):
                    do {
                        try await Task.sleep(timeInterval: interval)
                    } catch {
                        return logE { "failed to sleep a task" }
                    }
                }
            } while true
        }
    }
}

extension SSEService: Loggable {}
