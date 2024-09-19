import Api

actor MockApi: ApiProtocol {
    var _runMethodWithParams: (@Sendable (any ApiMethod) async throws(ApiError) -> any (Decodable & Sendable))?
    var _runMethodWithoutParams: (@Sendable (any ApiMethod) async throws(ApiError) -> any (Decodable & Sendable))?
    var _runMethodWithoutResponse: (@Sendable (any ApiMethod) async throws(ApiError) -> Void)?

    func run<Method>(method: Method) async throws(ApiError) -> Method.Response
    where Method: ApiMethod, Method.Response: Decodable & Sendable, Method.Parameters: Encodable & Sendable {
        // swiftlint:disable:next force_cast
        try await _runMethodWithParams!(method) as! Method.Response
    }

    func run<Method>(method: Method) async throws(ApiError) -> Method.Response
    where Method: ApiMethod, Method.Response: Decodable & Sendable, Method.Parameters == NoParameters {
        // swiftlint:disable:next force_cast
        try await _runMethodWithoutParams!(method) as! Method.Response
    }

    func run<Method>(method: Method) async throws(ApiError)
    where Method: ApiMethod, Method.Response == NoResponse, Method.Parameters: Encodable & Sendable {
        try await _runMethodWithoutResponse!(method)
    }
}
