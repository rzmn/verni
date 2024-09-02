import Foundation
import Networking
import Logging
internal import Base

fileprivate extension Endpoint {
    var pathWithoutTrailingSlash: String {
        path.hasSuffix("/") ? String(path.prefix(path.count - 1)) : path
    }
}

struct UrlBuilder<Request: NetworkRequest>: Loggable {
    private let endpoint: Endpoint
    private let request: Request
    let logger: Logger

    init(endpoint: Endpoint, request: Request, logger: Logger) {
        self.endpoint = endpoint
        self.request = request
        self.logger = logger
    }
}

extension UrlBuilder {
    func build() throws(NetworkServiceError) -> URL {
        let urlString = endpoint.pathWithoutTrailingSlash + request.path
        guard let url = URL(string: urlString) else {
            logE { "cannot build url with string \(urlString)" }
            throw .cannotBuildRequest(
                InternalError.error(
                    "cannot build url with string \(urlString)",
                    underlying: nil
                )
            )
        }
        guard !request.parameters.isEmpty else {
            return url
        }
        return url.appending(
            queryItems: request.parameters.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        )
    }
}
