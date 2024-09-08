import ApiService
import DataTransferObjects
import Api
import Combine
import Foundation
import Base

final class DefaultApi: ApiProtocol {
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
    ) async throws(LongPollError) -> [Query.Update]
    where Query: LongPollQuery, Query.Update: Decodable {
        let result: LongPollResultDto<Query.Update>
        do {
            result = try await service.run(
                request: AnyApiServiceRequest(
                    path: query.method,
                    parameters: [
                        "timeout": "\(longPollTimeout)",
                        "category": query.eventId
                    ],
                    httpMethod: .get
                )
            )
        } catch {
            switch error {
            case .noConnection(let error):
                throw .noConnection(error)
            case .decodingFailed(let error), .internalError(let error):
                throw .internalError(error)
            case .unauthorized:
                throw .internalError(error)
            }
        }
        switch result {
        case .success(let update):
            return update
        case .failure(let longPollFailure):
            switch longPollFailure {
            case .noUpdates:
                throw .noUpdates
            case .noConnection(let error):
                throw .noConnection(error)
            case .internalError(let error):
                throw .internalError(error)
            }
        }
    }

    func run<Method>(
        method: Method
    ) async throws(ApiError) -> Method.Response
    where Method: ApiMethod, Method.Response: Decodable & Sendable, Method.Parameters: Encodable & Sendable {
        if case .get = method.method {
            let request: ApiServiceRequest
            switch await createRequestFromGetMethod(method: method) {
            case .success(let success):
                request = success
            case .failure(let failure):
                throw failure
            }
            let call: () async throws(ApiServiceError) -> ApiResponseDto<Method.Response> = {
                try await self.service.run(request: request)
            }
            return try await mapApiResponse(call)
        } else {
            let call: () async throws(ApiServiceError) -> ApiResponseDto<Method.Response> = {
                try await self.service.run(
                    request: AnyApiServiceRequestWithBody(
                        request: AnyApiServiceRequest(
                            method: method
                        ),
                        body: method.parameters
                    )
                )
            }
            return try await mapApiResponse(call)
        }
    }

    func run<Method>(
        method: Method
    ) async throws(ApiError) -> Method.Response
    where Method: ApiMethod, Method.Response: Decodable, Method.Parameters == NoParameters {
        let call: () async throws(ApiServiceError) -> ApiResponseDto<Method.Response> = {
            try await self.service.run(
                request: AnyApiServiceRequest(method: method)
            )
        }
        return try await mapApiResponse(call)
    }

    func run<Method>(
        method: Method
    ) async throws(ApiError) -> Void
    where Method: ApiMethod, Method.Response == NoResponse, Method.Parameters: Encodable & Sendable {
        if case .get = method.method {
            let request: ApiServiceRequest
            switch await createRequestFromGetMethod(method: method) {
            case .success(let success):
                request = success
            case .failure(let failure):
                throw failure
            }
            let call: () async throws(ApiServiceError) -> VoidApiResponseDto = {
                try await self.service.run(request: request)
            }
            return try await mapApiResponse(call)
        } else {
            let call: () async throws(ApiServiceError) -> VoidApiResponseDto = {
                try await self.service.run(
                    request: AnyApiServiceRequestWithBody(
                        request: AnyApiServiceRequest(
                            method: method
                        ),
                        body: method.parameters
                    )
                )
            }
            return try await mapApiResponse(call)
        }
    }

    private func mapApiResponse<R: ApiResponse>(_ call: () async throws(ApiServiceError) -> R) async throws(ApiError) -> R.Success {
        let response: R
        do {
            response = try await call()
        } catch {
            switch error {
            case .noConnection(let error):
                throw .noConnection(error)
            case .decodingFailed(let error):
                throw .internalError(error)
            case .internalError(let error):
                throw .internalError(error)
            case .unauthorized:
                throw .api(.tokenExpired, description: nil)
            }
        }
        switch response.result {
        case .success(let response):
            return response
        case .failure(let error):
            throw .api(error.code, description: error.description)
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
