public struct NoParameters: Sendable {}

public struct NoResponse: Sendable {}

public protocol ApiMethod: Sendable {
    associatedtype Response: Sendable
    associatedtype Parameters: Sendable

    var path: String { get }
    var method: HttpMethod { get }
    var parameters: Parameters { get }
}

extension ApiMethod where Parameters == NoParameters {
    public var parameters: Parameters {
        NoParameters()
    }
}
