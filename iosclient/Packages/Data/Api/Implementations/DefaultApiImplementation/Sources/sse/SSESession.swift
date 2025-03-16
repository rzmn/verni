import Foundation
import AsyncExtensions
import Convenience
import Api
import Logging

actor SSESession {
    let logger: Logger
    
    private var state: State {
        didSet {
            logI { "sse session state changed: \(oldValue) -> \(state)" }
            if case .finished = oldValue {
                return
            }
            if case .finished = state {
                stream.continuation.finish()
            }
        }
    }
    private let urlSession: URLSession
    private let urlSessionTask: URLSessionTask
    private let dataDelegate: SSEDataDelegate
    private let stream: (stream: AsyncStream<RemoteUpdate>, continuation: AsyncStream<RemoteUpdate>.Continuation)
    
    private let chunkCollectorFactory: () -> ChunkCollector
    private let eventParserFactory: () -> EventParser
    
    init(
        logger: Logger,
        authHeaderValue: String?,
        url: URL,
        stream: (stream: AsyncStream<RemoteUpdate>, continuation: AsyncStream<RemoteUpdate>.Continuation),
        chunkCollectorFactory: @escaping () -> ChunkCollector,
        eventParserFactory: @escaping () -> EventParser
    ) {
        self.logger = logger
        self.chunkCollectorFactory = chunkCollectorFactory
        self.eventParserFactory = eventParserFactory
        self.stream = stream
        self.state = .initial
        
        dataDelegate = SSEDataDelegate()
        
        urlSession = URLSession(
            configuration: modify(URLSessionConfiguration.default) {
                $0.timeoutIntervalForRequest = 600
                $0.timeoutIntervalForResource = 3600
                $0.httpMaximumConnectionsPerHost = 1
                $0.requestCachePolicy = .reloadIgnoringLocalCacheData
                $0.networkServiceType = .responsiveData
                $0.shouldUseExtendedBackgroundIdleMode = true
                $0.connectionProxyDictionary = [:]
            },
            delegate: dataDelegate,
            delegateQueue: modify(OperationQueue()) {
                $0.name = "com.app.sse.delegate"
                $0.maxConcurrentOperationCount = 1
            }
        )
        urlSessionTask = urlSession.dataTask(
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
    
    deinit {
        print("[debug] sse session deinit")
    }
}

extension SSESession {
    enum State {
        case initial
        case connecting
        case connected
        case finished(TerminationReason)
    }
}

extension SSESession {
    enum InitializationFailureReason: Error {
        case nonHttpResponse(URLResponse)
        case tokenExpired
        case nonRetriableHttpError(Int)
    }
    
    func start() async -> Result<Void, InitializationFailureReason> {
        do {
            return .success(try await start())
        } catch {
            return .failure(error)
        }
    }
    
    func stop() async {
        urlSessionTask.cancel()
    }
    
    private func start() async throws(InitializationFailureReason) {
        guard case .initial = state else {
            return logE { "trying to start already started session" }
        }
        state = .connecting
        Task {
            await listenForEvents()
        }
        do {
            try await listenForResponse()
        } catch {
            state = .finished(.failed(error))
            logW { "failed to start sse session" }
            throw error
        }
    }
    
    private func listenForResponse() async throws(InitializationFailureReason) {
        var responseIterator = dataDelegate.responsePromise.makeAsyncIterator()
        urlSessionTask.resume()
        while let response = await responseIterator.next() {
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
    
    private func listenForEvents() async {
        let chunkCollector = chunkCollectorFactory()
        let eventParser = eventParserFactory()
        logD { "[debug] sse event loop start" }
        defer {
            logD { "[debug] sse event loop end" }
        }
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
                    stream.continuation.yield(update)
                }
            case .onComplete(let error):
                if let error {
                    state = .finished(.failed(error))
                } else {
                    state = .finished(.completed)
                }
            }
        }
    }
}

extension SSESession {
    enum TerminationReason: Error {
        case completed
        case failed(Error)
    }
}

extension SSESession: Loggable {}
