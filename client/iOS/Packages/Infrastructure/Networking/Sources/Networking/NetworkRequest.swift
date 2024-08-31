public protocol NetworkRequest {
    var path: String { get }
    var headers: [String: String] { get }
    var parameters: [String: String] { get }
    var httpMethod: String { get }
}

public protocol NetworkRequestWithBody: NetworkRequest {
    associatedtype Body: Encodable
    var body: Body { get }
}
