import Networking
internal import Base

struct RequestWithParameters<Parameters: Encodable>: NetworkRequestWithParameters, CompactDescription {
    private var request: Request
    let parameters: Parameters

    var path: String {
        request.path
    }

    var httpMethod: HttpMethod {
        request.httpMethod
    }

    var headers: [String : String] {
        request.headers
    }

    mutating func setHeader(key: String, value: String) {
        request.setHeader(key: key, value: value)
    }

    init(request: Request, parameters: Parameters) {
        self.request = request
        self.parameters = parameters
    }
}
