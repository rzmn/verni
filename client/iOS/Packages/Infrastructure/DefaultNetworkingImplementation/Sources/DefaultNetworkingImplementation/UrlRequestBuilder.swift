import Foundation
import Networking
import Logging
internal import Base

fileprivate extension NetworkRequestWithBody {
    func encodedBody(encoder: JSONEncoder) async throws -> Data {
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
    func build() async -> Result<URLRequest, NetworkServiceError> {
        var r = URLRequest(url: url)
        request.headers.forEach { key, value in
            r.setValue(value, forHTTPHeaderField: key)
            logD { "\(request.path): http header: (\(key): \(value))" }
        }
        r.httpMethod = request.httpMethod
        let httpBody: Data?
        switch await encodeBody(from: request) {
        case .success(let data):
            httpBody = data
        case .failure(let error):
            return .failure(error)
        }
        if let httpBody {
            r.setValue("application/json", forHTTPHeaderField: "Content-Type")
            r.httpBody = httpBody
        }
        return .success(r)
    }

    private func encodeBody<T: NetworkRequest>(
        from request: T
    ) async -> Result<Data?, NetworkServiceError> {
        guard let request = request as? (any NetworkRequestWithBody) else {
            return .success(nil)
        }
        let data: Data
        do {
            data = try await request.encodedBody(encoder: encoder)
        } catch {
            return .failure(
                .cannotBuildRequest(
                    InternalError.error(
                        "bad request body: \(request.body)",
                        underlying: error
                    )
                )
            )
        }
        return .success(data)
    }
}
