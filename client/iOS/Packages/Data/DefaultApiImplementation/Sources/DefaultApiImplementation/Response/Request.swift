import Networking
import Api
internal import Base

struct Request: NetworkRequest, CustomStringConvertible {
    let path: String
    private(set) var headers: [String : String]
    let httpMethod: Networking.HttpMethod

    init(method: any ApiMethod) {
        self.init(path: method.path, httpMethod: method.method)
    }

    init(path: String, headers: [String: String] = [:], httpMethod: Api.HttpMethod) {
        self.path = path
        self.headers = headers
        switch httpMethod {
        case .put:
            self.httpMethod = .put
        case .post:
            self.httpMethod = .post
        case .get:
            self.httpMethod = .get
        case .delete:
            self.httpMethod = .delete
        }
    }

    mutating func setHeader(key: String, value: String) {
        headers[key] = value
    }

    var description: String {
        "<m=\(httpMethod.rawValue) p=\(path) h=\(headers.mapValues { v in v.starts(with: "Bearer") ? "\(v.prefix("Bearer".count + 4)).."  : v })>"
    }
}
