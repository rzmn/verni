import ApiService
import Networking
import Foundation
import Logging
internal import Base

private extension TokenRefresher {
    func refreshTokensCallback(completion: @escaping @Sendable (Result<Void, RefreshTokenFailureReason>) -> Void) {
        func _refreshTokensCallback(completion: (Result<Void, RefreshTokenFailureReason>) -> Void) async {
            do {
                completion(.success(try await refreshTokens()))
            } catch {
                completion(.failure(error))
            }
        }
        Task.detached {
            await _refreshTokensCallback(completion: completion)
        }
    }
}

final class ApiServiceRequestRunnersManager: Loggable, Sendable {
    let logger: Logger = .shared
    private let tokenRefresher: TokenRefresher?

    private let stateQueue = DispatchQueue(label: "\(ApiServiceRequestRunnersManager.self).state")
    private let schedulerQueue = DispatchQueue(label: "\(ApiServiceRequestRunnersManager.self).scheduler")
    private let notifyQueue = DispatchQueue(label: "\(ApiServiceRequestRunnersManager.self).notify")

    private let refreshTokenSemaphore = DispatchSemaphore(value: 1)
    private let runnerFactory: ApiServiceRequestRunnerFactory
    enum RequestState: Sendable {
        case notInitialized
        case running
        case waitingForRun
    }
    /// on state queue
    nonisolated(unsafe) private var runningRequests = [UUID: RequestState]()

    init(runnerFactory: ApiServiceRequestRunnerFactory, tokenRefresher: TokenRefresher?) {
        self.tokenRefresher = tokenRefresher
        self.runnerFactory = runnerFactory
    }

    func run<Request: ApiServiceRequest, Response: Decodable & Sendable>(
        request: Request,
        completion: @escaping @Sendable (Result<Response, ApiServiceError>) -> Void
    ) {
        schedulerQueue.async {
            self.runUnchecked(request: request, id: UUID(), completion: completion)
        }
    }

    private func runUnchecked<Request: ApiServiceRequest, Response: Decodable & Sendable>(
        request: Request,
        id: UUID,
        completion: @escaping @Sendable (Result<Response, ApiServiceError>) -> Void
    ) {
        dispatchPrecondition(condition: .onQueue(schedulerQueue))
        waitUntilTokenIsRefreshed()
        self.stateQueue.async {
            self.runningRequests[id] = .running
            Task.detached {
                await self.runImpl(request: request, id: id, completion: completion)
            }
        }
    }

    private func runImpl<Request: ApiServiceRequest, Response: Decodable & Sendable>(
        request: Request,
        id: UUID,
        completion: @escaping @Sendable (Result<Response, ApiServiceError>) -> Void
    ) async {
        [stateQueue, notifyQueue, schedulerQueue].forEach {
            dispatchPrecondition(condition: .notOnQueue($0))
        }
        guard let tokenRefresher else {
            return await runImplNoAuth(request: request, id: id, completion: completion)
        }
        if let token = await tokenRefresher.accessToken() {
            let runner = runnerFactory.create(accessToken: token)
            let result: Result<Response, ApiServiceError> = await runner.run(request: request)
            switch result {
            case .success(let response):
                completeTask(id: id) {
                    completion(.success(response))
                }
            case .failure(let error):
                if case .unauthorized = error {
                    handleUnauthorized(request: request, id: id, tokenRefresher: tokenRefresher, completion: completion)
                } else {
                    completeTask(id: id) {
                        completion(.failure(error))
                    }
                }
            }
        } else {
            handleUnauthorized(request: request, id: id, tokenRefresher: tokenRefresher, completion: completion)
        }
    }

    private func handleUnauthorized<Request: ApiServiceRequest, Response: Decodable & Sendable>(
        request: Request,
        id: UUID,
        tokenRefresher: TokenRefresher,
        completion: @escaping @Sendable (Result<Response, ApiServiceError>) -> Void
    ) {
        [stateQueue, notifyQueue, schedulerQueue].forEach {
            dispatchPrecondition(condition: .notOnQueue($0))
        }
        stateQueue.async {
            switch self.runningRequests[id, default: .notInitialized] {
            case .waitingForRun:
                self.runningRequests[id] = nil
                self.schedulerQueue.async {
                    self.runUnchecked(request: request, id: id, completion: completion)
                }
            case .notInitialized:
                assertionFailure()
                let error = InternalError.error("internal inconsistency: task finished but it is not initialized", underlying: nil)
                self.completeTask(id: id) {
                    completion(.failure(.internalError(error)))
                }
            case .running:
                self.refreshToken(refresher: tokenRefresher) {
                    self.stateQueue.async {
                        self.runningRequests[id] = nil
                        self.schedulerQueue.async {
                            self.runUnchecked(request: request, id: id, completion: completion)
                        }
                    }
                } onFailure: { error in
                    switch error {
                    case .noConnection(let error):
                        self.completeTask(id: id) {
                            completion(.failure(.noConnection(error)))
                        }
                    case .internalError(let error):
                        self.completeTask(id: id) {
                            completion(.failure(.internalError(error)))
                        }
                    case .expired:
                        self.completeTask(id: id) {
                            completion(.failure(.unauthorized))
                        }
                    }
                }
            }
        }
    }

    private func refreshToken(
        refresher: TokenRefresher,
        onSuccess: @escaping @Sendable () -> Void,
        onFailure: @escaping @Sendable (RefreshTokenFailureReason) -> Void
    ) {
        dispatchPrecondition(condition: .onQueue(stateQueue))
        for key in self.runningRequests.keys {
            self.runningRequests[key] = .waitingForRun
        }
        self.refreshTokenSemaphore.wait()
        refresher.refreshTokensCallback { result in
            self.notifyQueue.async {
                switch result {
                case .success:
                    onSuccess()
                case .failure(let error):
                    onFailure(error)
                }
                self.refreshTokenSemaphore.signal()
            }
        }
    }

    private func runImplNoAuth<Request: ApiServiceRequest, Response: Decodable & Sendable>(
        request: Request,
        id: UUID,
        completion: @escaping @Sendable (Result<Response, ApiServiceError>) -> Void
    ) async {
        [stateQueue, notifyQueue, schedulerQueue].forEach {
            dispatchPrecondition(condition: .notOnQueue($0))
        }
        let result = await runnerFactory
            .create(accessToken: nil)
            .run(request: request)
        as Result<Response, ApiServiceError>
        stateQueue.async {
            self.runningRequests[id] = nil
            self.notifyQueue.async {
                completion(result)
            }
        }
    }

    private func completeTask(id: UUID, completion: @escaping @Sendable () -> Void) {
        [stateQueue, notifyQueue, schedulerQueue].forEach {
            dispatchPrecondition(condition: .notOnQueue($0))
        }
        stateQueue.async {
            self.runningRequests[id] = nil
            self.notifyQueue.async {
                completion()
            }
        }
    }

    private func waitUntilTokenIsRefreshed() {
        dispatchPrecondition(condition: .onQueue(schedulerQueue))
        refreshTokenSemaphore.wait()
        refreshTokenSemaphore.signal()
    }
}
