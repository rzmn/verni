import DataTransferObjects

public protocol ApiProtocol {
    func run<Method>(method: Method) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters: Encodable

    func run<Method>(method: Method) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters == NoParameters

    func run<Method>(method: Method) async -> ApiResult<Void>
    where Method: ApiMethod, Method.Response == NoResponse, Method.Parameters: Encodable

    func longPoll<Query>(query: Query) async -> LongPollResult<Query.Update>
    where Query: LongPollQuery
}
