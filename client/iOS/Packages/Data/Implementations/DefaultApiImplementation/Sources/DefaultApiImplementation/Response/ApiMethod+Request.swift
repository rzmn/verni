import Api
import ApiService
import Foundation

struct AnyApiServiceRequestWithBody<Body: Encodable & Sendable>: ApiServiceRequestWithBody {
    private var request: AnyApiServiceRequest

    let body: Body

    var path: String { request.path }
    var headers: [String: String] { request.headers }
    var parameters: [String: String] { request.parameters }
    var httpMethod: String { request.httpMethod }

    mutating func setHeader(key: String, value: String) {
        request.setHeader(key: key, value: value)
    }

    init(request: AnyApiServiceRequest, body: Body) {
        self.request = request
        self.body = body
    }
}
