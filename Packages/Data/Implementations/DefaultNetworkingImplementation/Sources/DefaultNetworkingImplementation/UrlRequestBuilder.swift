import Foundation
import Networking
import Logging
internal import Base

struct UrlRequestBuilder<Request: NetworkRequest>: Loggable {
    private let url: URL
    private let request: Request
    private let encoder: UrlRequestBuilderBodyEncoder
    let logger: Logger

    init(url: URL, request: Request, encoder: UrlRequestBuilderBodyEncoder, logger: Logger) {
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
        let httpBody = try encoder.encodeBody(from: request)
        if let httpBody {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = httpBody
        }
        return urlRequest
    }
}
