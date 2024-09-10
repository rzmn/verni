public protocol ApiProtocol: Sendable {
    func run<Method>(method: Method) async throws(ApiError) -> Method.Response
    where Method: ApiMethod, Method.Response: Decodable & Sendable, Method.Parameters: Encodable & Sendable

    func run<Method>(method: Method) async throws(ApiError) -> Method.Response
    where Method: ApiMethod, Method.Response: Decodable & Sendable, Method.Parameters == NoParameters

    func run<Method>(method: Method) async throws(ApiError)
    where Method: ApiMethod, Method.Response == NoResponse, Method.Parameters: Encodable & Sendable
}
