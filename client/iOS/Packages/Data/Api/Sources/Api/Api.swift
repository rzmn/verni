import DataTransferObjects

public protocol ApiProtocol {
    var friendsUpdated: AsyncStream<Void> { get }
    var spendingsUpdated: AsyncStream<Void> { get }

    func run<Method>(method: Method) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters: Encodable

    func run<Method>(method: Method) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters == Void

    func run<Method>(method: Method) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response == Void, Method.Parameters: Encodable
}
