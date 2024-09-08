import Networking
import ApiService

struct NetworkRequestAdapter<T: ApiServiceRequest>: NetworkRequest {
    var path: String {
        request.path
    }

    var headers: [String: String] {
        request.headers
    }

    var parameters: [String: String] {
        request.parameters
    }

    var httpMethod: String {
        request.httpMethod
    }

    private let request: T

    init(_ request: T) {
        self.request = request
    }
}

extension NetworkRequestAdapter: NetworkRequestWithBody where T: ApiServiceRequestWithBody {
    typealias Body = T.Body

    var body: T.Body {
        request.body
    }
}
