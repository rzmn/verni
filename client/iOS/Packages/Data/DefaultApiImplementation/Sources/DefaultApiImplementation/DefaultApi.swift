import ApiService
import DataTransferObjects
import Api
import Combine
import Foundation
internal import Base

class DefaultApi: ApiProtocol {
    private enum RefreshTokenError: Error {
        case internalError
    }
    private let service: ApiService
    private let encoder: JSONEncoder

    public init(service: ApiService) {
        self.service = service
        encoder = JSONEncoder()
    }
}

// MARK: Types

extension DefaultApi {
    typealias ApiServiceResponse<T: Decodable> = Result<ApiResponseDto<T>, ApiServiceError>
    typealias ApiServiceResultVoid = Result<VoidApiResponseDto, ApiServiceError>
}

extension DefaultApi {
    private var longPollTimeout: Int { 29 }

    func longPoll<Query>(
        query: Query
    ) async -> LongPollResult<[Query.Update]>
    where Query: LongPollQuery, Query.Update: Decodable {
        let result = await service.run(
            request: AnyApiServiceRequest(
                path: query.method,
                parameters: [
                    "timeout": "\(longPollTimeout)",
                    "category": query.eventId
                ], 
                httpMethod: .get
            )
        ) as Result<LongPollResultDto<Query.Update>, ApiServiceError>
        switch result {
        case .success(let longPollResult):
            switch longPollResult {
            case .success(let update):
                return .success(update)
            case .failure(let longPollFailure):
                switch longPollFailure {
                case .noUpdates:
                    return .failure(.noUpdates)
                case .noConnection(let error):
                    return .failure(.noConnection(error))
                case .internalError(let error):
                    return .failure(.internalError(error))
                }
            }
        case .failure(let error):
            switch error {
            case .noConnection(let error):
                return .failure(.noConnection(error))
            case .decodingFailed(let error), .internalError(let error):
                return .failure(.internalError(error))
            case .unauthorized:
                return .failure(.internalError(error))
            }
        }
    }

    func run<Method>(
        method: Method
    ) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters: Encodable {
        if case .get = method.method {
            let request: ApiServiceRequest
            switch await createRequestFromGetMethod(method: method) {
            case .success(let success):
                request = success
            case .failure(let failure):
                return .failure(failure)
            }
            let response: ApiServiceResponse<Method.Response> = await service.run(request: request)
            return mapApiResponse(response)
        } else {
            return mapApiResponse(
                await service.run(
                    request: AnyApiServiceRequestWithBody(
                        request: AnyApiServiceRequest(
                            method: method
                        ),
                        body: method.parameters
                    )
                ) as ApiServiceResponse<Method.Response>
            )
        }
    }

    func run<Method>(
        method: Method
    ) async -> ApiResult<Method.Response>
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters == NoParameters {
        mapApiResponse(
            await service.run(
                request: AnyApiServiceRequest(method: method)
            ) as ApiServiceResponse<Method.Response>
        )
    }

    func run<Method>(
        method: Method
    ) async -> ApiResult<Void>
    where Method: ApiMethod, Method.Response == NoResponse, Method.Parameters: Encodable {
        if case .get = method.method {
            let request: ApiServiceRequest
            switch await createRequestFromGetMethod(method: method) {
            case .success(let success):
                request = success
            case .failure(let failure):
                return .failure(failure)
            }
            let response: ApiServiceResultVoid = await service.run(request: request)
            return mapApiResponse(response)
        } else {
            return mapApiResponse(
                await service.run(
                    request: AnyApiServiceRequestWithBody(
                        request: AnyApiServiceRequest(
                            method: method
                        ),
                        body: method.parameters
                    )
                ) as ApiServiceResultVoid
            )
        }
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

    private func createRequestFromGetMethod<Method>(
        method: Method
    ) async -> Result<ApiServiceRequest, ApiError>
    where Method: ApiMethod, Method.Parameters: Encodable {
        let encoded: Data
        do {
            encoded = try encoder.encode(method.parameters)
        } catch {
            return .failure(.internalError(error))
        }
        guard let data = String(
            data: encoded,
            encoding: .utf8
        ) else {
            return .failure(
                .internalError(
                    InternalError.error("cannot build utf8 string from \(encoded)", underlying: nil)
                )
            )
        }
        return .success(
            AnyApiServiceRequest(
                method: method,
                parameters: [
                    "data": data
                ]
            )
        )
    }
}
