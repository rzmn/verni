import Foundation
import Networking
import Logging
internal import Base

fileprivate extension NetworkRequestWithBody {
    func encodedBody(encoder: JSONEncoder) throws -> Data {
        try encoder.encode(body)
    }
}

struct UrlRequestBuilder<Request: NetworkRequest>: Loggable {
    private let url: URL
    private let request: Request
    private let encoder: JSONEncoder
    let logger: Logger

    init(url: URL, request: Request, encoder: JSONEncoder, logger: Logger) {
        self.url = url
        self.request = request
        self.encoder = encoder
        self.logger = logger
    }
}

extension UrlRequestBuilder {
    func build() throws(NetworkServiceError) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
            logD { "\(request.path): http header: (\(key): \(value))" }
        }
        urlRequest.httpMethod = request.httpMethod
        let httpBody = try encodeBody(from: request)
        if let httpBody {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = httpBody
        }
        return urlRequest
    }

    private func encodeBody<T: NetworkRequest>(
        from request: T
    ) throws(NetworkServiceError) -> Data? {
        guard let request = request as? (any NetworkRequestWithBody) else {
            return nil
        }
        let data: Data
        do {
            data = try request.encodedBody(encoder: encoder)
        } catch {
            throw .cannotBuildRequest(
                InternalError.error(
                    "bad request body: \(request.body)",
                    underlying: error
                )
            )
        }
        return data
    }
}
