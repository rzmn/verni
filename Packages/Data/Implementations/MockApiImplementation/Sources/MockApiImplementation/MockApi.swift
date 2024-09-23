import Api

actor MockApi: ApiProtocol {
    var runMethodWithParamsBlock: (@Sendable (any ApiMethod) async throws(ApiError) -> any (Decodable & Sendable))?
    var runMethodWithoutParamsBlock: (@Sendable (any ApiMethod) async throws(ApiError) -> any (Decodable & Sendable))?
    var runMethodWithoutResponseBlock: (@Sendable (any ApiMethod) async throws(ApiError) -> Void)?

    func run<Method>(method: Method) async throws(ApiError) -> Method.Response
    where Method: ApiMethod, Method.Response: Decodable & Sendable, Method.Parameters: Encodable & Sendable {
        guard let runMethodWithParamsBlock else {
            fatalError("not implemented")
        }
        // swiftlint:disable:next force_cast
        return try await runMethodWithParamsBlock(method) as! Method.Response

    }

    func run<Method>(method: Method) async throws(ApiError) -> Method.Response
    where Method: ApiMethod, Method.Response: Decodable & Sendable, Method.Parameters == NoParameters {
        guard let runMethodWithoutParamsBlock else {
            fatalError("not implemented")
        }
        // swiftlint:disable:next force_cast
        return try await runMethodWithoutParamsBlock(method) as! Method.Response
    }

    func run<Method>(method: Method) async throws(ApiError)
    where Method: ApiMethod, Method.Response == NoResponse, Method.Parameters: Encodable & Sendable {
        guard let runMethodWithoutResponseBlock else {
            fatalError("not implemented")
        }
        try await runMethodWithoutResponseBlock(method)
    }
}
