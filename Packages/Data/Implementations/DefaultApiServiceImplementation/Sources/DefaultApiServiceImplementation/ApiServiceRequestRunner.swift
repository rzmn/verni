import ApiService
import Networking
import Foundation
import Logging

protocol ApiServiceRequestRunnerFactory: Sendable {
    func create(accessToken: String?) -> ApiServiceRequestRunner
}

protocol ApiServiceRequestRunner {
    func run(
        request: some ApiServiceRequest
    ) async throws(ApiServiceError) -> Data
}

final class DefaultApiServiceRequestRunnerFactory: ApiServiceRequestRunnerFactory {
    private let service: NetworkService
    private let logger: Logger

    init(
        logger: Logger,
        service: NetworkService
    ) {
        self.logger = logger
        self.service = service
    }

    func create(accessToken: String?) -> any ApiServiceRequestRunner {
        DefaultApiServiceRequestRunner(logger: logger, networkService: service, accessToken: accessToken)
    }
}

actor DefaultApiServiceRequestRunner: ApiServiceRequestRunner {
    let logger: Logger
    private let accessToken: String?
    private let networkService: NetworkService

    init(logger: Logger, networkService: NetworkService, accessToken: String? = nil) {
        self.accessToken = accessToken
        self.networkService = networkService
        self.logger = logger
    }

    func run(
        request: some ApiServiceRequest
    ) async throws(ApiServiceError) -> Data {
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
        return networkServiceResponse.data
    }
}

extension DefaultApiServiceRequestRunner: Loggable {}
