import ApiService
import Networking
import Foundation
import Logging

protocol ApiServiceRequestRunnerFactory: Sendable {
    func create(accessToken: String?) -> ApiServiceRequestRunner
}

protocol ApiServiceRequestRunner {
    func run<Request: ApiServiceRequest, Response: Decodable>(
        request: Request
    ) async -> Result<Response, ApiServiceError>
}

final class DefaultApiServiceRequestRunnerFactory: ApiServiceRequestRunnerFactory {
    private let service: NetworkService

    init(service: NetworkService) {
        self.service = service
    }

    func create(accessToken: String?) -> any ApiServiceRequestRunner {
        DefaultApiServiceRequestRunner(networkService: service, accessToken: accessToken)
    }
}

actor DefaultApiServiceRequestRunner: ApiServiceRequestRunner {
    private let accessToken: String?
    private let networkService: NetworkService
    private let decoder = JSONDecoder()

    init(networkService: NetworkService, accessToken: String? = nil) {
        self.accessToken = accessToken
        self.networkService = networkService
    }

    nonisolated func run<Request: ApiServiceRequest, Response: Decodable>(
        request: Request
    ) async -> Result<Response, ApiServiceError> {
        logI { "\(request): starting request" }
        var request = request
        if let accessToken, request.headers["Authorization"] == nil {
            logI { "\(request): got access token for setting to request" }
            request.setHeader(key: "Authorization", value: "Bearer \(accessToken)")
        }
        logI { "\(request): running request" }
        let networkServiceResponse: NetworkServiceResponse
        do {
            networkServiceResponse = try await networkService.run(NetworkRequestAdapter(request))
        } catch {
            logE { "\(request): request failed with reason error: \(error)" }
            switch error {
            case .cannotSend, .badResponse, .cannotBuildRequest:
                return .failure(.internalError(error))
            case .noConnection:
                return .failure(.noConnection(error))
            }
        }
        logI { "\(request): request succeeded with response \(networkServiceResponse)" }
        if case .clientError(let error) = networkServiceResponse.code, case .unauthorized = error {
            logI { "\(request): got unauthorized, try to refresh token" }
            return .failure(.unauthorized)
        }
        let apiServiceResponse: Response
        do {
            apiServiceResponse = try decoder.decode(Response.self, from: networkServiceResponse.data)
        } catch {
            logE { "\(request): request succeeded but decoding failed due error: \(error)" }
            if networkServiceResponse.code.success {
                logE { "\(request): recognized decoding failure as a decoding error" }
                return .failure(.decodingFailed(error))
            } else {
                logE { "\(request): recognized decoding failure as a unknown output" }
                return .failure(.internalError(error))
            }
        }
        return .success(apiServiceResponse)
    }
}

extension DefaultApiServiceRequestRunner: Loggable {}
