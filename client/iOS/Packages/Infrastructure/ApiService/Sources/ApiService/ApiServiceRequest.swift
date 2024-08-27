import Foundation

public protocol ApiServiceRequest {
    var path: String { get }
    var headers: [String: String] { get }
    var parameters: [String: String] { get }
    var httpMethod: String { get }

    mutating func setHeader(key: String, value: String)
}

public protocol ApiServiceRequestWithBody: ApiServiceRequest {
    associatedtype Body: Encodable
    var body: Body { get }
}
