import Foundation

public protocol ApiServiceRequest: Sendable {
    var path: String { get }
    var headers: [String: String] { get }
    var parameters: [String: String] { get }
    var httpMethod: String { get }

    mutating func setHeader(key: String, value: String)
}

public protocol ApiServiceRequestWithBody: ApiServiceRequest {
    var body: Data { get }
}
