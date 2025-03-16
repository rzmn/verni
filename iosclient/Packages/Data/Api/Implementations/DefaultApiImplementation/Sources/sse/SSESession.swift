import Foundation
import AsyncExtensions
import Api
import Logging

actor SSESession {
    let logger: Logger
    
    private let dataDelegate: SSEDataDelegate
    private let publisher: EventPublisher<RemoteUpdate>
    
    private let chunkCollectorFactory: () -> ChunkCollector
    private let eventParserFactory: () -> EventParser
    
    init(
        logger: Logger,
        dataDelegate: SSEDataDelegate,
        publisher: EventPublisher<RemoteUpdate>,
        chunkCollectorFactory: @escaping () -> ChunkCollector,
        eventParserFactory: @escaping () -> EventParser
    ) {
        self.dataDelegate = dataDelegate
        self.publisher = publisher
        self.logger = logger
        self.chunkCollectorFactory = chunkCollectorFactory
        self.eventParserFactory = eventParserFactory
    }
    
    enum InitializationFailureReason: Error {
        case nonHttpResponse(URLResponse)
        case tokenExpired
        case nonRetriableHttpError(Int)
    }
    
    func run() async -> Result<Task<Result<Void, TerminationReason>, Never>, InitializationFailureReason> {
        let task = Task<Result<Void, TerminationReason>, Never> {
            await listenForEvents()
        }
        do {
            try await listenForResponse()
        } catch {
            return .failure(error)
        }
        return .success(task)
    }
    
    private func listenForResponse() async throws(InitializationFailureReason) {
        for await response in dataDelegate.responsePromise {
            guard let httpResponse = response.value as? HTTPURLResponse else {
                logE { "invalid response type from SSE endpoint: \(response)" }
                throw .nonHttpResponse(response.value)
            }
            switch httpResponse.statusCode {
            case 200...299:
                logI { "initialized stream with code \(httpResponse.statusCode)" }
                response.disposition(.allow)
                return
            case 401:
                logW { "sse stream - expired" }
                throw .tokenExpired
            default:
                logW { "sse stream - failed [\(httpResponse.statusCode)]" }
                throw .nonRetriableHttpError(httpResponse.statusCode)
            }
        }
    }
    
    private func listenForEvents() async -> Result<Void, TerminationReason> {
        do {
            return .success(try await listenForEvents())
        } catch {
            return .failure(error)
        }
    }
    
    private func listenForEvents() async throws(TerminationReason) {
        let chunkCollector = chunkCollectorFactory()
        let eventParser = eventParserFactory()
        for await event in dataDelegate.eventStream {
            switch event {
            case .onData(let data):
                for collectorState in await chunkCollector.onDataReceived(data) {
                    let rawMessage: String
                    switch collectorState {
                    case .badFormat:
                        logW { "bad message format, skipping" }
                        continue
                    case .incomplete(let string):
                        logI { "waiting for the remaining part of the message, skipping" }
                        logD { "incomplete payload: \(string)" }
                        continue
                    case .completed(let string):
                        rawMessage = string
                    }
                    let event: SSESession.Event
                    do {
                        event = try await eventParser.process(message: rawMessage)
                    } catch {
                        logW { "failed to parse message: \(rawMessage)" }
                        continue
                    }
                    let update: RemoteUpdate
                    switch event {
                    case .connected:
                        logI { "connection notification received" }
                        continue
                    case .update(let value):
                        update = value
                    case .error(let reason):
                        logW { "error notification received: \(reason)" }
                        continue
                    }
                    logD { "publishing update \(update)" }
                    await publisher.notify(update)
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
    }
}

extension SSESession: Loggable {}
