import Networking

struct MockNetworkRequest: NetworkRequest {
    let path: String
    let headers: [String: String]
    let parameters: [String: String]
    let httpMethod: String
}

struct MockNetworkRequestBody: Codable, Equatable {
    let data: String
}

struct MockNetworkRequestWithBody<Body: Encodable & Sendable>: NetworkRequestWithBody {
    var path: String { impl.path }
    var headers: [String: String] { impl.headers }
    var parameters: [String: String] { impl.parameters }
    var httpMethod: String { impl.httpMethod }

    let body: Body
    private let impl: any NetworkRequest

    init<R: NetworkRequest>(request: R, body: Body) {
        self.body = body
        self.impl = request
    }
}
