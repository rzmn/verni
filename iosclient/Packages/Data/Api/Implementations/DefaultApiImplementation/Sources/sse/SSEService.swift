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
    private let tokenRepository: RefreshTokenRepository?
    
    init(
        taskFactory: TaskFactory,
        logger: Logger,
        endpoint: URL,
        tokenRepository: RefreshTokenRepository?,
        api: APIProtocol
    ) async {
        self.logger = logger.with(prefix: "[sse] ")
        self.taskFactory = taskFactory
        self.publisher = EventPublisher()
        self.tokenRepository = tokenRepository
        self.url = endpoint.appendingPathComponent("/operationsQueue")
        self.api = api
    }
    
    private func acquireSession(token: String) async throws(SSESession.TerminationReason) {
        urlSessionTask?.cancel()
        
        let delegate = SSEDataDelegate()
        let sseSession = SSESession(
            logger: logger,
            stream: delegate.eventStream,
            publisher: publisher
        )
        let task = Task { () async -> Result<Void, SSESession.TerminationReason> in
            await sseSession.run()
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
        urlSessionTask = urlSession.dataTask(
            with: modify(URLRequest(url: url)) {
                $0.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                $0.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                $0.setValue("text/event-stream", forHTTPHeaderField: "Content-Type")
                $0.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                $0.setValue("keep-alive", forHTTPHeaderField: "Connection")
                $0.httpMethod = "GET"
                $0.timeoutInterval = 600
            }
        )
        urlSessionTask?.resume()
        return try await task.value.get()
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
    
    private func pullExplicitly() async {
        let response: Operations.PullOperations.Output
        do {
            response = try await api.pullOperations(.init(query: .init(_type: .regular)))
        } catch {
            return logW { "failed to pull initial operations error: \(error)" }
        }
        let operations: [Components.Schemas.SomeOperation]
        switch response {
        case .ok(let payload):
            switch payload.body {
            case .json(let payload):
                operations = payload.response
            }
        default:
            return logW { "got api error pulling initial operations error: \(response)" }
        }
        await publisher.notify(.newOperationsAvailable(operations))
    }
    
    func start() async {
        guard let tokenRepository else {
            return logI { "does not support sse without user session" }
        }
        logI { "starting SSE service" }
        task = taskFactory.task { [weak self] in
            guard let self else { return }
            
            var accessToken: String?
            var needsReestablishment = false
            let retryInterval: TimeInterval = 5
            repeat {
                await pullExplicitly()
                
                guard let currentToken = await tokenRepository.accessToken() else {
                    logI { "no token, waiting for token data" }
                    do {
                        try await Task.sleep(timeInterval: retryInterval)
                    } catch {
                        return logE { "failed to sleep a task" }
                    }
                    continue
                }
                
                if accessToken == currentToken && !needsReestablishment {
                    logI { "same token, possibly invalid, waiting for new token data" }
                    do {
                        try await Task.sleep(timeInterval: retryInterval)
                    } catch {
                        return logE { "failed to sleep a task" }
                    }
                    continue
                }
                accessToken = currentToken
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
                        try await acquireSession(token: currentToken)
                        return .immediately
                    } catch {
                        switch error {
                        case .nonHttpResponse, .nonRetriableHttpError:
                            return .failed
                        case .tokenExpired, .completedWithError:
                            return .afterDelay(5)
                        }
                    }
                }
                switch await process() {
                case .immediately:
                    needsReestablishment = true
                case .failed:
                    needsReestablishment = false
                    return logI { "finishing sse stream" }
                case .afterDelay(let interval):
                    needsReestablishment = true
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
