import Networking
import Logging
import ApiService
import Foundation

actor DefaultApiService {
    let logger: Logger
    private let networkService: NetworkService
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let tokenRefresher: TokenRefresher?

    public init(
        logger: Logger,
        networkServiceFactory: NetworkServiceFactory,
        tokenRefresher: TokenRefresher? = nil
    ) {
        self.logger = logger
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

    private func refreshToken(_ tokenRefresher: TokenRefresher, requestDescription: String) async -> Result<String, ApiServiceError> {
        logI { "\(requestDescription): fetching access token for setting to request" }
        switch await tokenRefresher.refreshTokens() {
        case .success:
            if let token = await tokenRefresher.accessToken() {
                logI { "\(requestDescription): getting access token for setting to request: success" }
                return .success(token)
            } else {
                assertionFailure("\(requestDescription): has no access token after successful refresh")
                return .failure(.unauthorized)
            }
        case .failure(let reason):
            switch reason {
            case .noConnection(let error):
                return .failure(.noConnection(error))
            case .expired:
                logE { "\(requestDescription): token was expired" }
                return .failure(.unauthorized)
            case .internalError(let error):
                logE { "\(requestDescription): cannot update token due internal error: \(error)" }
                return .failure(.unauthorized)
            }
        }
    }

    public func run<Request: NetworkRequest, Response: Decodable>(
        request: Request,
        tryToRefreshTokenIfNeeded: Bool
    ) async -> Result<Response, ApiServiceError> {
        logI { "\(request): starting request" }
        var tryToRefreshTokenIfNeeded = tryToRefreshTokenIfNeeded
        var request = request
        if let tokenRefresher, request.headers["Authorization"] == nil {
            if let token = await tokenRefresher.accessToken() {
                logI { "\(request): got access token for setting to request" }
                request.setHeader(key: "Authorization", value: "Bearer \(token)")
            } else {
                tryToRefreshTokenIfNeeded = false
                switch await refreshToken(tokenRefresher, requestDescription: "\(request)") {
                case .success(let token):
                    request.setHeader(key: "Authorization", value: "Bearer \(token)")
                case .failure(let reason):
                    return .failure(reason)
                }
            }
        }
        logI { "\(request): running request" }
        switch await networkService.run(request) {
        case .success(let networkServiceResponse):
            logI { "\(request): request succeeded with response \(networkServiceResponse)" }
            do {
                if let tokenRefresher, case .clientError(let error) = networkServiceResponse.code, case .unauthorized = error, tryToRefreshTokenIfNeeded {
                    logI { "\(request): got unauthorized, try to refresh token" }
                    switch await refreshToken(tokenRefresher, requestDescription: "\(request)") {
                    case .success:
                        return await run(request: request, tryToRefreshTokenIfNeeded: false)
                    case .failure(let reason):
                        return .failure(reason)
                    }
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

extension DefaultApiService: Loggable {}
