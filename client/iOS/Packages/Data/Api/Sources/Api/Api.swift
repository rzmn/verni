import DataTransferObjects
import Combine

public protocol ApiProtocol {
    func run<Method>(method: Method) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters: Encodable

    func run<Method>(method: Method) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters == NoParameters

    func run<Method>(method: Method) async -> ApiResult<Void>
    where Method: ApiMethod, Method.Response == NoResponse, Method.Parameters: Encodable
}

public protocol LongPoll {
    func create<Query: LongPollQuery>(for query: Query) async -> AnyPublisher<Query.Update, Never>
}
