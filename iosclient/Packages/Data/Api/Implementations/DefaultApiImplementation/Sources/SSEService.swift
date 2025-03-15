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
    
    enum ProcessEventsTerminationReason: Error {
        case completedWithError(Error)
        case nonHttpResponse(URLResponse)
        case tokenExpired
        
        case nonRetriableHttpError(Int)
    }
    struct StreamNotification: Decodable {
        let type: String
    }
    struct NewOperationsAvailableNotification: Decodable {
        let response: [Components.Schemas.SomeOperation]
    }
    actor IsConnectedBox {
        var value = false
    }
    
    private func processEvents(token: String) async throws(ProcessEventsTerminationReason) {
        urlSessionTask?.cancel()
        
        let delegate = SSEDataDelegate()
        let task = Task { () async -> Result<Void, ProcessEventsTerminationReason> in
            var connected = false
            var incompleteMessage: String?
            for await event in delegate.eventStream {
                switch event {
                case .onData(let data):
                    guard let message = String(data: data, encoding: .utf8) else {
                        logW { "unknown data encoding \(data)" }
                        continue
                    }
                    let prefix = "data: "
                    let payload: String
                    if message.hasPrefix(prefix) {
                        if let incomplete = incompleteMessage {
                            logW { "got new message when had an incomplete one, skipping incomplete one [incomplete: \(incomplete), received: \(message)]" }
                            incompleteMessage = nil
                        }
                        let formatted = String(message.dropFirst(prefix.count))
                        if formatted.hasSuffix("\n\n") {
                            payload = formatted
                        } else {
                            incompleteMessage = formatted
                            logI { "got incomplete message \(formatted), waiting for next chunk" }
                            continue
                        }
                    } else {
                        if let incomplete = incompleteMessage {
                            if message.hasSuffix("\n\n") {
                                payload = incomplete + message
                                incompleteMessage = nil
                            } else {
                                let formatted = incomplete + message
                                logI { "keep incomplete message \(formatted), waiting for next chunk" }
                                incompleteMessage = formatted
                                continue
                            }
                        } else {
                            logW { "unknown message format for message: \(message)" }
                            continue
                        }
                    }
                    logI { "got event \(payload)" }
                    do {
                        if connected {
                            await publisher.notify(
                                .newOperationsAvailable(
                                    try JSONDecoder().decode(
                                        NewOperationsAvailableNotification.self,
                                        from: Data(payload.utf8)
                                    ).response
                                )
                            )
                        } else {
                            let notification = try JSONDecoder().decode(
                                StreamNotification.self,
                                from: Data(payload.utf8)
                            )
                            if notification.type == "connected" {
                                connected = true
                                logI { "connection established" }
                            } else {
                                logW { "unknown notification type \(notification.type)" }
                            }
                        }
                    } catch {
                        logE { "failed to decode SSE data error: \(error)" }
                    }
                case .onResponse(let response, let disposition):
                    guard let httpResponse = response as? HTTPURLResponse else {
                        logE { "invalid response type from SSE endpoint: \(response)" }
                        return .failure(.nonHttpResponse(response))
                    }
                    switch httpResponse.statusCode {
                    case 200...299:
                        logI { "initialized stream with code \(httpResponse.statusCode)" }
                        disposition(.allow)
                    case 401:
                        logW { "sse stream - expired" }
                        return .failure(.tokenExpired)
                    default:
                        logW { "sse stream - failed [\(httpResponse.statusCode)]" }
                        return .failure(.nonRetriableHttpError(httpResponse.statusCode))
                    }
                case .onComplete(let error):
                    if let error {
                        return .failure(.completedWithError(error))
                    } else {
                        return .success(())
                    }
                }
            }
            return .success(())
        }
        let session = URLSession(
            configuration: modify(URLSessionConfiguration.default) {
                // Increase timeouts for long-lived connections
                $0.timeoutIntervalForRequest = 600  // 10 minutes
                $0.timeoutIntervalForResource = 3600 // 1 hour
                
                // SSE requires one connection per host
                $0.httpMaximumConnectionsPerHost = 1
                $0.requestCachePolicy = .reloadIgnoringLocalCacheData
                
                // SSE should be foreground priority
                $0.networkServiceType = .responsiveData
                
                // Enable keep-alive
                $0.shouldUseExtendedBackgroundIdleMode = true
                
                // Disable proxy to ensure direct connection
                $0.connectionProxyDictionary = [:]
            },
            delegate: delegate,
            delegateQueue: modify(OperationQueue()) {
                $0.name = "com.app.sse.delegate"
                $0.maxConcurrentOperationCount = 1
            }
        )
        
        urlSessionTask = session.dataTask(
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
        
        // Cancel the current data task first
        urlSessionTask?.cancel()
        urlSessionTask = nil
        
//        // Then invalidate the session
//        await urlSession?.finishTasksAndInvalidate()
//        urlSession = nil
//        delegate = nil
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
            var retryInterval: TimeInterval = 5
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
                        try await processEvents(token: currentToken)
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
                        try await Task.sleep(timeInterval: retryInterval)
                    } catch {
                        return logE { "failed to sleep a task" }
                    }
                }
            } while true
        }
    }
}

extension SSEService: Loggable {}

// Make SSEDataDelegate retain itself while the session is active
final class SSEDataDelegate: NSObject, URLSessionDataDelegate {
    enum Event: Sendable {
        case onData(Data)
        case onResponse(URLResponse, disposition: @Sendable (URLSession.ResponseDisposition) -> Void)
        case onComplete(Error?)
    }
    private let internalStream = AsyncStream<Event>.makeStream()
    var eventStream: AsyncStream<Event> { internalStream.stream }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        internalStream.continuation.yield(.onData(data))
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        internalStream.continuation.yield(.onComplete(error))
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        internalStream.continuation.yield(.onResponse(response, disposition: completionHandler))
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        completionHandler(.performDefaultHandling, nil)
    }
}
