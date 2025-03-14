import Api
import Convenience
import AsyncExtensions
import Logging
import Foundation

actor SSEService {
    private let publisher: EventPublisher<RemoteUpdate>
    private let url: URL
    private var task: Task<Void, Never>?
    
    let logger: Logger
    private let taskFactory: TaskFactory
    private let tokenRepository: RefreshTokenRepository?
    private let session: URLSession
    
    init(
        taskFactory: TaskFactory, 
        logger: Logger, 
        endpoint: URL,
        tokenRepository: RefreshTokenRepository?,
        session: URLSession = .shared
    ) async {
        self.logger = logger.with(prefix: "[sse] ")
        self.taskFactory = taskFactory
        self.session = session
        self.publisher = EventPublisher()
        self.tokenRepository = tokenRepository
        self.url = endpoint.appendingPathComponent("/operationsQueue")
    }
    
    enum ProcessEventsTerminationReason: Error {
        case failedToCreateStream(Error)
        case nonHttpResponse(URLResponse)
        case tokenExpired
        case failedToConsumeUpdate(Error)
        case nonRetriableHttpError(Int)
    }
    
    private func processEvents(token: String) async throws(ProcessEventsTerminationReason) {
        let stream: URLSession.AsyncBytes
        let response: URLResponse
        do {
            (stream, response) = try await session.bytes(
                for: modify(URLRequest(url: url)) {
                    $0.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
            )
        } catch {
            logE { "failed to create stream error: \(error)" }
            throw .failedToCreateStream(error)
        }
        logI { "listening for events..." }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logE { "invalid response type from SSE endpoint: \(response)" }
            throw .nonHttpResponse(response)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            logI { "initialized stream with code \(httpResponse.statusCode)" }
        case 401:
            logW { "sse stream - expired" }
            throw .tokenExpired
        default:
            logW { "sse stream - failed [\(httpResponse.statusCode)]" }
            throw .nonRetriableHttpError(httpResponse.statusCode)
        }
        
        do {
            for try await line in stream.lines {
                let prefix = "data: "
                guard line.hasPrefix(prefix) else { continue }
                
                let jsonData = line.dropFirst(prefix.count)
                logI { "got event \(jsonData)" }
                
                do {
                    await publisher.notify(
                        .newOperationsAvailable(
                            try JSONDecoder().decode(
                                [Components.Schemas.SomeOperation].self,
                                from: Data(jsonData.utf8)
                            )
                        )
                    )
                } catch {
                    logE { "failed to decode SSE data error: \(error)" }
                }
            }
        } catch {
            logW { "sse stream - failed to consume update error: \(error)" }
            throw .failedToConsumeUpdate(error)
        }
    }
}

extension SSEService: RemoteUpdatesService {
    var eventSource: any EventSource<RemoteUpdate> {
        publisher
    }
    
    func start() async {
        guard let tokenRepository else {
            return logI { "does not support sse without user session" }
        }
        logI { "starting SSE service" }
        task = taskFactory.task { [weak self] in
            guard let self else { return }
            
            var accessToken: String?
            repeat {
                guard let currentToken = await tokenRepository.accessToken() else {
                    logI { "no token, waiting for token data" }
                    do {
                        try await Task.sleep(timeInterval: 1)
                    } catch {
                        return logE { "failed to sleep a task" }
                    }
                    continue
                }
                if accessToken == currentToken {
                    logI { "same token, possibly invalid, waiting for new token data" }
                    do {
                        try await Task.sleep(timeInterval: 1)
                    } catch {
                        return logE { "failed to sleep a task" }
                    }
                    continue
                }
                accessToken = currentToken
                if Task.isCancelled {
                    return
                }
                func process() async -> Bool {
                    do {
                        try await processEvents(token: currentToken)
                    } catch {
                        switch error {
                        case .failedToCreateStream, .nonHttpResponse, .nonRetriableHttpError:
                            return false
                        case .tokenExpired, .failedToConsumeUpdate:
                            return true
                        }
                    }
                    return true
                }
                guard await process() else {
                    return
                }
                logI { "needs to reestablish sse stream" }
                do {
                    try await Task.sleep(timeInterval: 1)
                } catch {
                    return logE { "failed to sleep a task" }
                }
                continue
            } while true
        }
    }
    
    func stop() async {
        logI { "stopping SSE service" }
        task?.cancel()
        task = nil
    }
}

extension SSEService: Loggable {}
