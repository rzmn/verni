import Api
import Foundation
import Logging
import Convenience

actor DefaultServerSideEventsSession {
    let logger: Logger
    
    private var state: State {
        didSet {
            logI { "sse session state changed: \(oldValue) -> \(state)" }
            if case .finished = oldValue {
                return
            }
            if case .finished = state {
                stream.continuation.finish()
                switch oldValue {
                case .initial, .finished, .initializing:
                    break
                case .connecting(let dataTask), .connected(let dataTask):
                    dataTask.cancel()
                }
                urlSession.invalidateAndCancel()
            }
        }
    }
    private let urlSession: URLSession
    private let dataDelegate: DataDelegate
    private let stream: (stream: AsyncStream<RemoteUpdate>, continuation: AsyncStream<RemoteUpdate>.Continuation)
    private let urlConfiguration: UrlConfiguration
    
    private let chunkCollectorFactory: () -> ChunkCollector
    private let eventParserFactory: () -> EventParser
    
    init(
        logger: Logger,
        urlConfiguration: UrlConfiguration,
        stream: (stream: AsyncStream<RemoteUpdate>, continuation: AsyncStream<RemoteUpdate>.Continuation),
        chunkCollectorFactory: @escaping () -> ChunkCollector,
        eventParserFactory: @escaping () -> EventParser
    ) {
        self.logger = logger
        self.chunkCollectorFactory = chunkCollectorFactory
        self.eventParserFactory = eventParserFactory
        self.stream = stream
        self.state = .initial
        self.urlConfiguration = urlConfiguration
        dataDelegate = DataDelegate(
            logger: logger.with(
                prefix: "[url.delegate]"
            )
        )
        urlSession = URLSession(
            configuration: urlConfiguration.sessionConfiguration(),
            delegate: dataDelegate,
            delegateQueue: modify(OperationQueue()) {
                $0.name = "com.app.sse.delegate"
                $0.maxConcurrentOperationCount = 1
            }
        )
        Task {
            await listenForEvents()
        }
    }
}

extension DefaultServerSideEventsSession {
    enum State {
        case initial
        case initializing
        case connecting(URLSessionDataTask)
        case connected(URLSessionDataTask)
        case finished(TerminationReason)
    }
}

extension DefaultServerSideEventsSession: ServerSideEventsSession {
    nonisolated var updatesStream: AsyncStream<RemoteUpdate> {
        stream.stream
    }
    
    func stop() {
        state = .finished(.failed(InternalError.error("canceled")))
    }
    
    func start() async throws(SessionStartError) {
        guard case .initial = state else {
            return logE { "trying to start already started session" }
        }
        state = .initializing
        let request = await urlConfiguration.urlRequest()
        do {
            try Task.checkCancellation()
        } catch {
            logI { "failed to initialize sse session error: \(error)" }
            state = .finished(.failed(error))
            throw .canceled
        }
        let dataTask = urlSession.dataTask(with: request)
        state = .connecting(dataTask)
        do {
            try await perform(dataTask: dataTask)
        } catch {
            state = .finished(.failed(error))
            logW { "failed to start sse session error: \(error)" }
            throw error
        }
        state = .connected(dataTask)
    }
    
    private func perform(dataTask: URLSessionDataTask) async throws(SessionStartError) {
        var responseIterator = dataDelegate.responsePromise.makeAsyncIterator()
        dataTask.resume()
        let next = { () async throws(SessionStartError) -> DataDelegate.Response? in
            let value: DataDelegate.Response?
            do {
                value = try await responseIterator.next()
            } catch {
                guard !Task.isCancelled else {
                    throw .canceled
                }
                if let error = error.noConnection {
                    throw .retriableError(.general(error))
                } else {
                    throw .nonRetriableError(.general(error))
                }
            }
            guard !Task.isCancelled else {
                throw .canceled
            }
            return value
        }
        while let response = try await next() {
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
                response.disposition(.cancel)
                throw .tokenExpired
            case 408, // Request Timeout
                 429, // Too Many Requests
                 500...599: // Server Errors
                logW { "sse stream - retriable error [\(httpResponse.statusCode)]" }
                response.disposition(.cancel)
                throw .retriableError(.http(httpResponse.statusCode))
            default:
                logW { "sse stream - non-retriable error [\(httpResponse.statusCode)]" }
                response.disposition(.cancel)
                throw .nonRetriableError(.http(httpResponse.statusCode))
            }
        }
    }
    
    private func listenForEvents() async {
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
                    let event: SessionEvent
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
                    case .disconnected:
                        logI { "disconnected notification received" }
                        state = .finished(.completed)
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

extension DefaultServerSideEventsSession {
    enum TerminationReason: Error {
        case completed
        case failed(Error)
    }
}

extension DefaultServerSideEventsSession: Loggable {}
