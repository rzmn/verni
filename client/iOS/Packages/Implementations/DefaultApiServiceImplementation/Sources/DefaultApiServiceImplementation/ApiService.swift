import Networking
import Logging
import ApiService
import Foundation

class DefaultApiService {
    private let networkService: NetworkService
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let _logger: Logger
    private let tokenRefresher: TokenRefresher?

    public init(
        logger: Logger,
        networkServiceFactory: NetworkServiceFactory,
        tokenRefresher: TokenRefresher? = nil
    ) {
        self._logger = logger
        self.networkService = networkServiceFactory.create()
        self.tokenRefresher = tokenRefresher
        logI { "initialized network service. has token refresher: \(tokenRefresher != nil)" }
    }
}

extension DefaultApiService: ApiService {
    public func run<Request: NetworkRequest, Response: Decodable>(
        request: Request
    ) async -> Result<Response, ApiServiceError> {
        await run(request: request, tryToRefreshTokenIfNeeded: true)
    }

    public func run<Request: NetworkRequest, Response: Decodable>(
        request: Request,
        tryToRefreshTokenIfNeeded: Bool
    ) async -> Result<Response, ApiServiceError> {
        logI { "\(request): starting request" }
        var request = request
        if let tokenRefresher, request.headers["Authorization"] == nil {
            logE { "setting access token to request" }
            request.setHeader(key: "Authorization", value: "Bearer \(tokenRefresher.accessToken)")
        }
        logI { "\(request): running request" }
        switch await networkService.run(request) {
        case .success(let networkServiceResponse):
            logI { "\(request): request succeeded with response \(networkServiceResponse)" }
            do {
                if let tokenRefresher,
                   case .clientError(let error) = networkServiceResponse.code,
                   case .unauthorized = error,
                   tryToRefreshTokenIfNeeded,
                   await tokenRefresher.refreshTokens()
                {
                    logI { "\(request): refreshed token" }
                    return await run(request: request, tryToRefreshTokenIfNeeded: false)
                }
                return .success(try decoder.decode(Response.self, from: networkServiceResponse.data))
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
        case .failure(let error):
            logE { "\(request): request failed with reason error: \(error)" }
            switch error {
            case .cannotSend, .badResponse, .cannotBuildRequest:
                return .failure(.internalError(error))
            case .noConnection:
                return .failure(.noConnection(error))
            }
        }
    }
}

extension DefaultApiService: Loggable {
    public var logger: Logger {
        _logger
    }
}
