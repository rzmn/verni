import Foundation
import Logging

final class DataDelegate: NSObject, URLSessionDataDelegate, Sendable {
    let logger: Logger
    private let internalStream = AsyncStream<Event>.makeStream()
    var eventStream: AsyncStream<Event> {
        internalStream.stream
    }
    
    private let internalPromise = AsyncThrowingStream<Response, Error>.makeStream()
    var responsePromise: AsyncThrowingStream<Response, Error> {
        internalPromise.stream
    }
    
    init(logger: Logger) {
        self.logger = logger
        super.init()
    }
    
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
        if let error {
            logger.logI { "task did complete, error: \(error)" }
        } else {
            logger.logI { "task did complete" }
        }
        internalStream.continuation.yield(.onComplete(error))
        internalStream.continuation.finish()
        internalPromise.continuation.finish(throwing: error)
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        internalPromise.continuation.yield(
            Response(
                value: response,
                disposition: completionHandler
            )
        )
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        completionHandler(.performDefaultHandling, nil)
    }
}

extension DataDelegate {
    struct Response: Sendable {
        let value: URLResponse
        let disposition: @Sendable (URLSession.ResponseDisposition) -> Void
    }
    
    enum Event: Sendable {
        case onData(Data)
        case onComplete(Error?)
    }
}

extension DataDelegate: Loggable {}
