import Foundation
import AsyncExtensions
import Convenience
import Api
import Logging

enum SessionStartError: Error {
    enum ErrorKind {
        case http(Int)
        case general(Error)
    }
    case nonHttpResponse(URLResponse)
    case tokenExpired
    case nonRetriableError(ErrorKind)
    case retriableError(ErrorKind)
    
    static var canceled: SessionStartError {
        .nonRetriableError(.general(InternalError.error("session is canceled")))
    }
}

protocol ServerSideEventsSession: Sendable {
    var updatesStream: AsyncStream<RemoteUpdate> { get }
    
    func start() async throws(SessionStartError)
    func stop() async
}

extension ServerSideEventsSession {
    func start() async -> Result<Void, SessionStartError> {
        do {
            return .success(try await start())
        } catch {
            return .failure(error)
        }
    }
}

