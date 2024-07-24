import Networking
import Base

struct Request: NetworkRequest, CustomStringConvertible {
    let path: String
    private(set) var headers: [String : String]
    let httpMethod: HttpMethod

    mutating func setHeader(key: String, value: String) {
        headers[key] = value
    }

    var description: String {
        "<m=\(httpMethod.rawValue) p=\(path) h=\(headers.mapValues { v in v.starts(with: "Bearer") ? "\(v.prefix("Bearer".count + 4)).."  : v })>"
    }
}
