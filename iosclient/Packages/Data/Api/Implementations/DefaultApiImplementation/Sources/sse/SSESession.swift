import Foundation
import AsyncExtensions
import Api
import Logging

actor SSESession {
    let logger: Logger
    
    private let stream: AsyncStream<SSEDataDelegate.Event>
    private let publisher: EventPublisher<RemoteUpdate>
    
    init(
        logger: Logger,
        stream: AsyncStream<SSEDataDelegate.Event>,
        publisher: EventPublisher<RemoteUpdate>
    ) {
        self.stream = stream
        self.publisher = publisher
        self.logger = logger
    }
    
    func run() async -> Result<Void, TerminationReason> {
        do {
            return .success(try await run())
        } catch {
            return .failure(error)
        }
    }
    
    func run() async throws(TerminationReason) {
        let chunkCollector = ChunkCollector(logger: logger)
        let eventPublisher = EventParser(logger: logger)
        for await event in stream {
            switch event {
            case .onData(let data):
                logD { "got data \(data)" }
                guard let message = await chunkCollector.onDataReceived(data) else {
                    continue
                }
                guard let event = await eventPublisher.process(message: message) else {
                    continue
                }
                await publisher.notify(event)
            case .onResponse(let response, let disposition):
                guard let httpResponse = response as? HTTPURLResponse else {
                    logE { "invalid response type from SSE endpoint: \(response)" }
                    throw .nonHttpResponse(response)
                }
                switch httpResponse.statusCode {
                case 200...299:
                    logI { "initialized stream with code \(httpResponse.statusCode)" }
                    disposition(.allow)
                case 401:
                    logW { "sse stream - expired" }
                    throw .tokenExpired
                default:
                    logW { "sse stream - failed [\(httpResponse.statusCode)]" }
                    throw .nonRetriableHttpError(httpResponse.statusCode)
                }
            case .onComplete(let error):
                if let error {
                    throw .completedWithError(error)
                } else {
                    return
                }
            }
        }
    }
}

extension SSESession {
    enum TerminationReason: Error {
        case completedWithError(Error)
        case nonHttpResponse(URLResponse)
        case tokenExpired
        
        case nonRetriableHttpError(Int)
    }
}

extension SSESession: Loggable {}
