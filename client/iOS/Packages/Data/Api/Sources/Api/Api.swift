import DataTransferObjects
import Combine

public enum ApiEvent {
    case friendsUpdated
    case spendingCounterpartiesUpdated
    case spendingsHistoryUpdated(with: UserDto.ID)
}

public protocol ApiProtocol {
    var eventQueue: AnyPublisher<ApiEvent, Never> { get }

    func run<Method>(method: Method) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters: Encodable

    func run<Method>(method: Method) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters == NoParameters

    func run<Method>(method: Method) async -> ApiResult<Void>
    where Method: ApiMethod, Method.Response == NoResponse, Method.Parameters: Encodable
}
