public protocol ApiMethod {
    associatedtype Response
    associatedtype Parameters

    var path: String { get }
    var method: HttpMethod { get }
    var parameters: Parameters { get }
}

extension ApiMethod where Parameters == Void {
    public var parameters: Parameters {
        ()
    }
}
