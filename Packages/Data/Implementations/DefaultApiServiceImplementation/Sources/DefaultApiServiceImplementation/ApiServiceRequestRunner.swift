import ApiService
import Networking
import Foundation
import Logging

protocol ApiServiceRequestRunnerFactory: Sendable {
    func create(accessToken: String?) -> ApiServiceRequestRunner
}

protocol ApiServiceRequestRunner {
    func run<Response: Decodable & Sendable>(
        request: some ApiServiceRequest
    ) async throws(ApiServiceError) -> Response
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

    func run<Response: Decodable & Sendable>(
        request: some ApiServiceRequest
    ) async throws(ApiServiceError) -> Response {
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
                throw .internalError(error)
            case .noConnection:
                throw .noConnection(error)
            }
        }
        logI { "\(request): request succeeded with response \(networkServiceResponse)" }
        if case .clientError(let error) = networkServiceResponse.code, case .unauthorized = error {
            logI { "\(request): got unauthorized, try to refresh token" }
            throw .unauthorized
        }
        let apiServiceResponse: Response
        do {
            apiServiceResponse = try decoder.decode(Response.self, from: networkServiceResponse.data)
        } catch {
            logE { "\(request): request succeeded but decoding failed due error: \(error)" }
            if networkServiceResponse.code.success {
                logE { "\(request): recognized decoding failure as a decoding error" }
                throw .decodingFailed(error)
            } else {
                logE { "\(request): recognized decoding failure as a unknown output" }
                throw .internalError(error)
            }
        }
        return apiServiceResponse
    }
}

extension DefaultApiServiceRequestRunner: Loggable {}
