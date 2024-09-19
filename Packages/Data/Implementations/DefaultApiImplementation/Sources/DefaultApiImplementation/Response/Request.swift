import ApiService
import Api
import Base

private extension String {
    var httpHeaderDescription: String {
        starts(with: "Bearer") ? prefix("Bearer".count + 4) + "..." : self
    }
}

struct AnyApiServiceRequest: ApiServiceRequest, CustomStringConvertible {
    let parameters: [String: String]
    let path: String
    private(set) var headers: [String: String]
    let httpMethod: String

    init(
        path: String,
        headers: [String: String] = [:],
        parameters: [String: String],
        httpMethod: HttpMethod
    ) {
        self.path = path
        self.headers = headers
        self.parameters = parameters
        switch httpMethod {
        case .put:
            self.httpMethod = "PUT"
        case .post:
            self.httpMethod = "POST"
        case .get:
            self.httpMethod =  "GET"
        case .delete:
            self.httpMethod = "DELETE"
        }
    }

    init<T: ApiMethod>(method: T, parameters: [String: String] = [:]) {
        self = Self(
            path: method.path,
            headers: [:],
            parameters: parameters,
            httpMethod: method.method
        )
    }

    mutating func setHeader(key: String, value: String) {
        headers[key] = value
    }

    var description: String {
        "<" + [
            "m=\(httpMethod)",
            "p=\(path)",
            "h=\(headers.mapValues(\.httpHeaderDescription))"
        ].joined(separator: ", ") + ">"
    }
}
