import Foundation
import Networking

extension Error {
    var networkServiceError: NetworkServiceError {
        let error = self as NSError
        guard error.domain == NSURLErrorDomain else {
            return .cannotSend(error)
        }
        let noConnectionCodes: [URLError.Code] = [
            .networkConnectionLost,
            .timedOut,
            .notConnectedToInternet
        ]
        guard noConnectionCodes.map(\.rawValue).contains(error.code) else {
            return .cannotSend(error)
        }
        return .noConnection(error)
    }
}
