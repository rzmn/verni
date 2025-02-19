import OpenAPIRuntime
import HTTPTypes
import Logging
import Foundation
import AsyncExtensions
import Convenience
import Api

actor RefreshTokenMiddleware {
    let tokenRepository: RefreshTokenRepository
    let taskFactory: TaskFactory
    let logger: Logger

    enum State {
        case initial(Task<Bool /* have token */, Never>?)
        case refreshFailed(requestId: UUID, error: URLError)
        case refreshing(Task<Void, Never>)
        case authenticated(token: String)
        case unauthorized(reason: String)
    }

    private var state: State {
        didSet {
            logI { "state updated: \(oldValue) -> \(state)" }
        }
    }

    init(
        tokenRepository: RefreshTokenRepository,
        taskFactory: TaskFactory,
        logger: Logger
    ) {
        self.tokenRepository = tokenRepository
        self.taskFactory = taskFactory
        self.logger = logger
        self.state = .initial(nil)
    }
}

extension RefreshTokenMiddleware: ClientMiddleware {
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        try await doIntercept(
            request,
            body: body,
            baseURL: baseURL,
            operationID: operationID,
            requestID: UUID(),
            next: next
        )
    }

    private func doIntercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        requestID: UUID,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        switch state {
        case .initial(let task):
            if let task {
                let haveToken = await task.value
                if haveToken {
                    return try await doIntercept(
                        request,
                        body: body,
                        baseURL: baseURL,
                        operationID: operationID,
                        requestID: requestID,
                        next: next
                    )
                } else {
                    return try await refreshAndReshedule(
                        request,
                        body: body,
                        baseURL: baseURL,
                        operationID: operationID,
                        requestID: requestID,
                        next: next
                    )
                }
            } else {
                state = .initial(
                    taskFactory.task {
                        if let token = await self.tokenRepository.accessToken() {
                            self.state = .authenticated(token: token)
                            return true
                        } else {
                            return false
                        }
                    }
                )
                return try await doIntercept(
                    request,
                    body: body,
                    baseURL: baseURL,
                    operationID: operationID,
                    requestID: requestID,
                    next: next
                )
            }
        case .refreshing(let task):
            await task.value
            return try await doIntercept(
                request,
                body: body,
                baseURL: baseURL,
                operationID: operationID,
                requestID: requestID,
                next: next
            )
        case .authenticated(let token):
            do {
                return try await next(
                    modify(request) {
                        $0.headerFields[.authorization] = "Bearer \(token)"
                    },
                    body,
                    baseURL
                )
            } catch {
                throw error
            }
        case .refreshFailed(let failedRequestID, let error):
            if failedRequestID == requestID {
                throw error
            } else {
                return try await refreshAndReshedule(
                    request,
                    body: body,
                    baseURL: baseURL,
                    operationID: operationID,
                    requestID: requestID,
                    next: next
                )
            }
        case .unauthorized(let reason):
            let response = HTTPResponse(
                status: HTTPResponse.Status(
                    code: HTTPResponse.Status.unauthorized.code,
                    reasonPhrase: reason
                )
            )
            return (response, nil)
        }
    }

    private func refreshAndReshedule(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        requestID: UUID,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        func refresh() async -> State {
            do {
                try await tokenRepository.refreshTokens()
                if let token = await tokenRepository.accessToken() {
                    return .authenticated(token: token)
                } else {
                    return .unauthorized(reason: "missing token data after refresh")
                }
            } catch {
                switch error {
                case .noConnection:
                    return .refreshFailed(requestId: requestID, error: URLError.noConnection)
                case .expired(let error):
                    return .unauthorized(reason: "token expired: \(error)")
                case .internalError(let error):
                    return .unauthorized(reason: "failed to refresh token: \(error)")
                }
            }
        }
        switch state {
        case .refreshing, .initial, .refreshFailed:
            break
        case .authenticated, .unauthorized:
            assertionFailure("refreshing token from invalid state \(state)")
        }
        switch state {
        case .refreshing:
            break
        default:
            state = .refreshing(
                taskFactory.task {
                    self.state = await refresh()
                }
            )
        }
        return try await doIntercept(
            request,
            body: body,
            baseURL: baseURL,
            operationID: operationID,
            requestID: requestID,
            next: next
        )
    }
}

extension RefreshTokenMiddleware: Loggable {}
