import Foundation

public enum NetworkServiceError: Error {
    case cannotBuildRequest(Error)
    case cannotSend(Error)
    case badResponse(Error)
    case noConnection(Error)
}

extension NetworkServiceError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cannotBuildRequest(let error):
            return "cannot build req due error: \(error)"
        case .cannotSend(let error):
            return "cannot send req due error: \(error)"
        case .badResponse(let error):
            return "cannot handle response due error: \(error)"
        case .noConnection(let error):
            return "connection lost: \(error)"
        }
    }
}

public struct NetworkServiceResponse {
    public let code: HttpCode
    public let data: Data

    public init(code: HttpCode, data: Data) {
        self.code = code
        self.data = data
    }
}

public protocol NetworkRequest {
    var path: String { get }
    var headers: [String: String] { get }
    var httpMethod: HttpMethod { get }

    mutating func setHeader(key: String, value: String)
}

public protocol NetworkRequestWithParameters: NetworkRequest {
    associatedtype Parameters: Encodable
    var parameters: Parameters { get }
}

public protocol NetworkService {
    func run<T: NetworkRequest>(_ request: T) async -> Result<NetworkServiceResponse, NetworkServiceError>
}
