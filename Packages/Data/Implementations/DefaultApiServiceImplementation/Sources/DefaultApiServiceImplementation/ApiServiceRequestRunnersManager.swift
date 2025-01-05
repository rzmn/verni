import ApiService
import Networking
import Foundation
import Logging
import Base
import AsyncExtensions

actor ApiServiceRequestRunnersManager: Loggable {
    let logger: Logger
    private let tokenRefresher: TokenRefresher?
    private let runnerFactory: ApiServiceRequestRunnerFactory
    private let taskFactory: TaskFactory
    enum RequestStatus: Sendable {
        case regular
        case freshRefreshTokenConsumer
    }
    private var refreshTokenTask: Task<Void, any Error>?
    private var refreshTokenFailureReason: RefreshTokenFailureReason?

    init(
        runnerFactory: ApiServiceRequestRunnerFactory,
        taskFactory: TaskFactory,
        logger: Logger,
        tokenRefresher: TokenRefresher?
    ) {
        self.tokenRefresher = tokenRefresher
        self.taskFactory = taskFactory
        self.logger = logger
        self.runnerFactory = runnerFactory
    }

    func run(
        request: some ApiServiceRequest
    ) async throws(ApiServiceError) -> Data {
        try await run(request: request, status: .regular)
    }
}

// MARK: - Private

extension ApiServiceRequestRunnersManager {
    private func run(
        request: some ApiServiceRequest,
        status: RequestStatus
    ) async throws(ApiServiceError) -> Data {
        guard let tokenRefresher else {
            return try await runnerFactory
                .create(accessToken: nil)
                .run(request: request)
        }
        try await waitForRefreshTokenTaskIfNeeded()
        if let accessToken = await tokenRefresher.accessToken() {
            return try await run(
                with: accessToken,
                tokenRefresher: tokenRefresher,
                request: request,
                status: status
            )
        } else {
            switch status {
            case .regular:
                refreshTokenTask = taskFactory.task {
                    try await tokenRefresher.refreshTokens()
                }
                return try await run(request: request, status: .freshRefreshTokenConsumer)
            case .freshRefreshTokenConsumer:
                if let refreshTokenFailureReason {
                    switch refreshTokenFailureReason {
                    case .noConnection(let error):
                        throw .noConnection(error)
                    case .expired:
                        throw .unauthorized
                    case .internalError(let error):
                        throw .internalError(error)
                    }
                } else {
                    assertionFailure()
                    throw .internalError(
                        InternalError.error("no refresh token after successfull refresh", underlying: nil)
                    )
                }
            }
        }
    }

    private func waitForRefreshTokenTaskIfNeeded() async throws(ApiServiceError) {
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
                refreshTokenFailureReason = failureReason
                switch failureReason {
                case .noConnection:
                    break
                case .expired, .internalError:
                    throw .unauthorized
                }
            }
            self.refreshTokenTask = nil
        }
    }

    private func run(
        with accessToken: String,
        tokenRefresher: TokenRefresher,
        request: some ApiServiceRequest,
        status: RequestStatus
    ) async throws(ApiServiceError) -> Data {
        switch status {
        case .regular:
            let result: Result<Data, ApiServiceError>
            do {
                result = .success(
                    try await runnerFactory
                        .create(accessToken: accessToken)
                        .run(request: request)
                )
            } catch {
                result = .failure(error)
            }
            switch result {
            case .success(let result):
                return result
            case .failure(let error):
                switch error {
                case .internalError, .noConnection:
                    throw error
                case .unauthorized:
                    refreshTokenTask = taskFactory.task {
                        try await tokenRefresher.refreshTokens()
                    }
                    return try await run(request: request, status: .freshRefreshTokenConsumer)
                }
            }
        case .freshRefreshTokenConsumer:
            return try await runnerFactory
                .create(accessToken: accessToken)
                .run(request: request)
        }
    }
}
