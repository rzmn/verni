import XCTest
import HTTPTypes
import Logging
import TestInfrastructure
import Api
import OpenAPIRuntime
@testable import DefaultApiImplementation

final class RefreshTokenMiddlewareTests: XCTestCase {
    let infrastructure = TestInfrastructureLayer()
    
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
    
    func testSuccessfulRequestWithExistingToken() async throws {
        // Given
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
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(capturedRequest?.headerFields[.authorization], "Bearer valid_token")
        XCTAssertEqual(repository.refreshCallCount, 0)
    }
    
    func testAutoRefreshWhenNoToken() async throws {
        // Given
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
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(capturedRequest?.headerFields[.authorization], "Bearer new_token_1")
        XCTAssertEqual(repository.refreshCallCount, 1)
    }
    
    func testUnauthorizedWhenRefreshFails() async throws {
        // Given
        let repository = MockTokenRepository()
        repository.shouldFailRefresh = true
        repository.refreshError = .expired(NSError(domain: "test", code: -1))
        
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
                XCTFail("Next should not be called when refresh fails")
                return (HTTPResponse(status: .ok), nil)
            }
        )
        
        // Then
        XCTAssertEqual(response.status.code, HTTPResponse.Status.unauthorized.code)
        XCTAssertEqual(repository.refreshCallCount, 1)
    }
    
    func testRetryWithNoConnectionError() async throws {
        // Given
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
                    XCTFail("Next should not be called when refresh fails")
                    return (HTTPResponse(status: .ok), nil)
                }
            )
            XCTFail("Should throw an error")
        } catch {
            // Then
            XCTAssert((error as? URLError)?.noConnection != nil)
            XCTAssertEqual(repository.refreshCallCount, 1)
        }
    }
    
    func testConcurrentRequestsShareRefresh() async throws {
        // Given
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
            next: { request, _, _ in
                return (HTTPResponse(status: .ok), nil)
            }
        )
        
        async let request2 = middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test2"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test2",
            next: { request, _, _ in
                return (HTTPResponse(status: .ok), nil)
            }
        )
        
        // Then
        let (response1, response2) = try await (request1, request2)
        XCTAssertEqual(response1.0.status, .ok)
        XCTAssertEqual(response2.0.status, .ok)
        XCTAssertEqual(repository.refreshCallCount, 1, "Multiple concurrent requests should share one refresh")
    }
    
    func testExpiredTokenError() async throws {
        // Given
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
                XCTFail("Next should not be called when refresh fails with expired token")
                return (HTTPResponse(status: .ok), nil)
            }
        )
        
        // Then
        XCTAssertEqual(response.status.code, HTTPResponse.Status.unauthorized.code)
        XCTAssertEqual(repository.refreshCallCount, 1)
    }
    
    func testInternalErrorDuringRefresh() async throws {
        // Given
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
                XCTFail("Next should not be called when refresh fails with internal error")
                return (HTTPResponse(status: .ok), nil)
            }
        )
        
        // Then
        XCTAssertEqual(response.status.code, HTTPResponse.Status.unauthorized.code)
        XCTAssertEqual(repository.refreshCallCount, 1)
    }
    
    func testNoConnectionErrorDuringRefresh() async throws {
        // Given
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
                    XCTFail("Next should not be called when refresh fails with no connection")
                    return (HTTPResponse(status: .ok), nil)
                }
            )
            XCTFail("Should throw an error")
        } catch let error as URLError {
            // Then
            XCTAssertEqual(error.code, .notConnectedToInternet)
            XCTAssertEqual(repository.refreshCallCount, 1)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
} 
