import Foundation

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
