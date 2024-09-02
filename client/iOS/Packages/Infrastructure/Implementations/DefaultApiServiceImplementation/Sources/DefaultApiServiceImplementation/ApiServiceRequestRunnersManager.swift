import ApiService
import Networking
import Foundation
import Logging
internal import Base

actor ApiServiceRequestRunnersManager: Loggable {
    let logger: Logger = .shared
    private let tokenRefresher: TokenRefresher?
    private let runnerFactory: ApiServiceRequestRunnerFactory
    enum RequestStatus: Sendable {
        case regular
        case freshRefreshTokenConsumer
    }
    private var refreshTokenTask: Task<Void, any Error>?
    private var refreshTokenFailureReason: RefreshTokenFailureReason?

    init(runnerFactory: ApiServiceRequestRunnerFactory, tokenRefresher: TokenRefresher?) {
        self.tokenRefresher = tokenRefresher
        self.runnerFactory = runnerFactory
    }

    func run<Request: ApiServiceRequest, Response: Decodable & Sendable>(
        request: Request
    ) async -> Result<Response, ApiServiceError> {
        await run(request: request, status: .regular)
    }

    func run<Request: ApiServiceRequest, Response: Decodable & Sendable>(
        request: Request,
        status: RequestStatus
    ) async -> Result<Response, ApiServiceError> {
        guard let tokenRefresher else {
            return await runnerFactory
                .create(accessToken: nil)
                .run(request: request)
        }
        if let refreshTokenTask {
            switch await refreshTokenTask.result {
            case .success:
                break
            case .failure(let error):
                let failureReason: RefreshTokenFailureReason
                if let error = error as? RefreshTokenFailureReason {
                    failureReason = error
                } else {
                    failureReason = .internalError(error)
                }
                switch failureReason {
                case .noConnection:
                    break
                case .expired, .internalError:
                    return .failure(.unauthorized)
                }
            }
            self.refreshTokenTask = nil
        }
        if let accessToken = await tokenRefresher.accessToken() {
            switch status {
            case .regular:
                let result: Result<Response, ApiServiceError> = await runnerFactory
                    .create(accessToken: accessToken)
                    .run(request: request)
                switch result {
                case .success:
                    return result
                case .failure(let error):
                    switch error {
                    case .decodingFailed, .internalError, .noConnection:
                        return result
                    case .unauthorized:
                        refreshTokenTask = Task {
                            try await tokenRefresher.refreshTokens()
                        }
                        return await run(request: request, status: .freshRefreshTokenConsumer)
                    }
                }
            case .freshRefreshTokenConsumer:
                return await runnerFactory
                    .create(accessToken: accessToken)
                    .run(request: request)
            }
        } else {
            switch status {
            case .regular:
                refreshTokenTask = Task {
                    try await tokenRefresher.refreshTokens()
                }
                return await run(request: request, status: .freshRefreshTokenConsumer)
            case .freshRefreshTokenConsumer:
                if let refreshTokenFailureReason {
                    switch refreshTokenFailureReason {
                    case .noConnection(let error):
                        return .failure(.noConnection(error))
                    case .expired:
                        return .failure(.unauthorized)
                    case .internalError(let error):
                        return .failure(.internalError(error))
                    }
                } else {
                    assertionFailure()
                    return .failure(
                        .internalError(
                            InternalError.error("no refresh token after successfull refresh", underlying: nil)
                        )
                    )
                }
            }
        }
    }
}
