import HTTPTypes
import Logging
import TestInfrastructure
import Api
import OpenAPIRuntime
import Testing
import Foundation
@testable import DefaultApiImplementation

@Suite("RefreshToken Middleware Tests")
struct RefreshTokenMiddlewareTests {
    final class MockTokenRepository: @unchecked Sendable, RefreshTokenRepository {
        var currentToken: String?
        var shouldFailRefresh = false
        var refreshError: RefreshTokenFailureReason?
        var refreshCallCount = 0
        
        func accessToken() async -> String? {
            currentToken
        }
        
        func refreshTokens() async throws(RefreshTokenFailureReason) {
            refreshCallCount += 1
            if shouldFailRefresh {
                if let error = refreshError {
                    throw error
                }
                throw RefreshTokenFailureReason.internalError(NSError(domain: "test", code: -1))
            }
            currentToken = "new_token_\(refreshCallCount)"
        }
    }
    
    @Test("Successful request with existing token")
    func successfulRequestWithExistingToken() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let repository = MockTokenRepository()
        repository.currentToken = "valid_token"
        
        let middleware = RefreshTokenMiddleware(
            tokenRepository: repository,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        
        var capturedRequest: HTTPRequest?
        let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { request, _, _ in
            capturedRequest = request
            return (HTTPResponse(status: .ok), nil)
        }
        
        // When
        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test",
            next: next
        )
        
        // Then
        #expect(response.status == .ok)
        #expect(capturedRequest?.headerFields[.authorization] == "Bearer valid_token")
        #expect(repository.refreshCallCount == 0)
    }
    
    @Test("Auto refresh when no token")
    func autoRefreshWhenNoToken() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let repository = MockTokenRepository()
        
        let middleware = RefreshTokenMiddleware(
            tokenRepository: repository,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        
        var capturedRequest: HTTPRequest?
        let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { request, _, _ in
            capturedRequest = request
            return (HTTPResponse(status: .ok), nil)
        }
        
        // When
        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test",
            next: next
        )
        
        // Then
        #expect(response.status == .ok)
        #expect(capturedRequest?.headerFields[.authorization] == "Bearer new_token_1")
        #expect(repository.refreshCallCount == 1)
    }
    
    @Test("Unauthorized when refresh fails")
    func unauthorizedWhenRefreshFails() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let repository = MockTokenRepository()
        repository.shouldFailRefresh = true
        repository.refreshError = .expired(NSError(domain: "test", code: -1))
        
        let middleware = RefreshTokenMiddleware(
            tokenRepository: repository,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        
        var nextCalled = false
        
        // When
        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test",
            next: { _, _, _ in
                nextCalled = true
                return (HTTPResponse(status: .ok), nil)
            }
        )
        
        // Then
        #expect(nextCalled == false, "Next should not be called when refresh fails")
        #expect(response.status.code == HTTPResponse.Status.unauthorized.code)
        #expect(repository.refreshCallCount == 1)
    }
    
    @Test("Retry with no connection error")
    func retryWithNoConnectionError() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let repository = MockTokenRepository()
        repository.shouldFailRefresh = true
        repository.refreshError = .noConnection(URLError(.notConnectedToInternet))
        
        let middleware = RefreshTokenMiddleware(
            tokenRepository: repository,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        
        var nextCalled = false
        var didThrow = false
        
        // When
        do {
            _ = try await middleware.intercept(
                HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
                body: nil,
                baseURL: URL(string: "https://example.com")!,
                operationID: "test",
                next: { _, _, _ in
                    nextCalled = true
                    return (HTTPResponse(status: .ok), nil)
                }
            )
        } catch let error as URLError {
            didThrow = true
            // Then
            #expect(error.code == .notConnectedToInternet)
            #expect(repository.refreshCallCount == 1)
        } catch {
            #expect(false, "Unexpected error type: \(error)")
        }
        
        #expect(nextCalled == false, "Next should not be called when refresh fails")
        #expect(didThrow == true, "Should throw an error")
    }
    
    @Test("Concurrent requests share refresh")
    func concurrentRequestsShareRefresh() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let repository = MockTokenRepository()
        
        let middleware = RefreshTokenMiddleware(
            tokenRepository: repository,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        
        // When
        async let request1 = middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test1"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test1",
            next: { _, _, _ in (HTTPResponse(status: .ok), nil) }
        )
        
        async let request2 = middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test2"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test2",
            next: { _, _, _ in (HTTPResponse(status: .ok), nil) }
        )
        
        // Then
        let (response1, response2) = try await (request1, request2)
        #expect(response1.0.status == .ok)
        #expect(response2.0.status == .ok)
        #expect(repository.refreshCallCount == 1, "Multiple concurrent requests should share one refresh")
    }
    
    @Test("Expired token error")
    func expiredTokenError() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let repository = MockTokenRepository()
        repository.shouldFailRefresh = true
        let expectedError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token expired"])
        repository.refreshError = .expired(expectedError)
        
        let middleware = RefreshTokenMiddleware(
            tokenRepository: repository,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        
        // When
        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test",
            next: { _, _, _ in
                Issue.record("Next should not be called when refresh fails with expired token")
                return (HTTPResponse(status: .ok), nil)
            }
        )
        
        // Then
        #expect(response.status.code == HTTPResponse.Status.unauthorized.code)
        #expect(repository.refreshCallCount == 1)
    }
    
    @Test("Internal error during refresh")
    func internalErrorDuringRefresh() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let repository = MockTokenRepository()
        repository.shouldFailRefresh = true
        let expectedError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Internal server error"])
        repository.refreshError = .internalError(expectedError)
        
        let middleware = RefreshTokenMiddleware(
            tokenRepository: repository,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        
        // When
        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test",
            next: { _, _, _ in
                Issue.record("Next should not be called when refresh fails with internal error")
                return (HTTPResponse(status: .ok), nil)
            }
        )
        
        // Then
        #expect(response.status.code == HTTPResponse.Status.unauthorized.code)
        #expect(repository.refreshCallCount == 1)
    }
    
    @Test("No connection error during refresh")
    func noConnectionErrorDuringRefresh() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let repository = MockTokenRepository()
        repository.shouldFailRefresh = true
        repository.refreshError = .noConnection(URLError(.notConnectedToInternet))
        
        let middleware = RefreshTokenMiddleware(
            tokenRepository: repository,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        
        // When
        do {
            _ = try await middleware.intercept(
                HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
                body: nil,
                baseURL: URL(string: "https://example.com")!,
                operationID: "test",
                next: { _, _, _ in
                    Issue.record("Next should not be called when refresh fails with no connection")
                    return (HTTPResponse(status: .ok), nil)
                }
            )
            Issue.record("Should throw an error")
        } catch let error as URLError {
            // Then
            #expect(error.code == .notConnectedToInternet)
            #expect(repository.refreshCallCount == 1)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
} 
