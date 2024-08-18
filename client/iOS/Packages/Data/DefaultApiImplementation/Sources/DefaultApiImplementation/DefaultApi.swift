import ApiService
import Networking
import Base
import DataTransferObjects
import Api
import Combine

class DefaultApi: ApiProtocol {
    private enum RefreshTokenError: Error {
        case internalError
    }
    public let _eventQueue = PassthroughSubject<ApiEvent, Never>()
    public var eventQueue: AnyPublisher<ApiEvent, Never> {
        _eventQueue.eraseToAnyPublisher()
    }

    private let service: ApiService

    public init(service: ApiService, polling: ApiPolling? = nil) {
        self.service = service
    }
}

// MARK: Types

extension DefaultApi {
    typealias ApiServiceResponse<T: Decodable> = Result<ApiResponseDto<T>, ApiServiceError>
    typealias ApiServiceResultVoid = Result<VoidApiResponseDto, ApiServiceError>
}

extension DefaultApi {
    func run<Method>(
        method: Method
    ) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters: Encodable {
        mapApiResponse(
            await service.run(
                request: RequestWithParameters(
                    request: Request(
                        method: method
                    ),
                    parameters: method.parameters
                )
            ) as ApiServiceResponse<Method.Response>
        )
    }

    func run<Method>(
        method: Method
    ) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters == NoParameters {
        mapApiResponse(
            await service.run(
                request: Request(method: method)
            ) as ApiServiceResponse<Method.Response>
        )
    }

    func run<Method>(
        method: Method
    ) async -> ApiResult<Void>
    where Method: ApiMethod, Method.Response == NoResponse, Method.Parameters: Encodable {
        mapApiResponse(
            await service.run(
                request: RequestWithParameters(
                    request: Request(method: method),
                    parameters: method.parameters
                )
            ) as ApiServiceResultVoid
        )
    }

    private func mapApiResponse<R: ApiResponse>(_ response: Result<R, ApiServiceError>) -> ApiResult<R.Success> {
        switch response {
        case .success(let response):
            switch response.result {
            case .success(let response):
                return .success(response)
            case .failure(let error):
                return .failure(.api(error.code, description: error.description))
            }
        case .failure(let error):
            switch error {
            case .noConnection(let error):
                return .failure(.noConnection(error))
            case .decodingFailed(let error):
                return .failure(.internalError(error))
            case .internalError(let error):
                return .failure(.internalError(error))
            case .unauthorized:
                return .failure(.api(.tokenExpired, description: nil))
            }
        }
    }
}
