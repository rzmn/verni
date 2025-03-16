import Foundation

final class SSEDataDelegate: NSObject, URLSessionDataDelegate {
    struct Response: Sendable {
        let value: URLResponse
        let disposition: @Sendable (URLSession.ResponseDisposition) -> Void
    }
    enum Event: Sendable {
        case onData(Data)
        case onComplete(Error?)
    }
    private let internalStream = AsyncStream<Event>.makeStream()
    var eventStream: AsyncStream<Event> {
        internalStream.stream
    }
    private let internalPromise = AsyncStream<Response>.makeStream()
    var responsePromise: AsyncStream<Response> {
        internalPromise.stream
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
        internalStream.continuation.yield(.onComplete(error))
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
