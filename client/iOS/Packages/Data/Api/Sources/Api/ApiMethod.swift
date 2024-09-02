public struct NoParameters {}

public struct NoResponse {}

public protocol ApiMethod: Sendable {
    associatedtype Response
    associatedtype Parameters

    var path: String { get }
    var method: HttpMethod { get }
    var parameters: Parameters { get }
}

extension ApiMethod where Parameters == NoParameters {
    public var parameters: Parameters {
        NoParameters()
    }
}
