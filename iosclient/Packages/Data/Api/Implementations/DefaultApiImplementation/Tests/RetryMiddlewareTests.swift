import XCTest
import HTTPTypes
import Logging
import TestInfrastructure
import Api
import OpenAPIRuntime
@testable import DefaultApiImplementation

final class RetryMiddlewareTests: XCTestCase {
    let infrastructure = TestInfrastructureLayer()
    
    func testSuccessfulRequestWithoutRetry() async throws {
        // Given
        let middleware = RetryingMiddleware(
            logger: infrastructure.logger,
            taskFactory: infrastructure.taskFactory,
            signals: [.code(500)],
            policy: .upToAttempts(count: 3),
            delay: .exponential(interval: 0.1, attempt: 1, base: 2)
        )
        
        var callCount = 0
        let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
            callCount += 1
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
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testNonRetriableError() async throws {
        // Given
        let middleware = RetryingMiddleware(
            logger: infrastructure.logger,
            taskFactory: infrastructure.taskFactory,
            signals: [.code(500)],
            policy: .upToAttempts(count: 3),
            delay: .exponential(interval: 0.1, attempt: 1, base: 2)
        )
        
        var callCount = 0
        let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
            callCount += 1
            return (HTTPResponse(status: .badRequest), nil) // 400 is not in retry signals
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
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(response.status, .badRequest)
    }
    
    func testRetriableErrorWithSuccess() async throws {
        // Given
        let middleware = RetryingMiddleware(
            logger: infrastructure.logger,
            taskFactory: infrastructure.taskFactory,
            signals: [.code(500)],
            policy: .upToAttempts(count: 3),
            delay: .exponential(interval: 0.1, attempt: 1, base: 2)
        )
        
        var callCount = 0
        let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
            callCount += 1
            if callCount == 1 {
                return (HTTPResponse(status: .internalServerError), nil) // 500 should trigger retry
            }
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
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(response.status, .ok)
    }
    
    func testRetriableErrorExhaustsAttempts() async throws {
        // Given
        let middleware = RetryingMiddleware(
            logger: infrastructure.logger,
            taskFactory: infrastructure.taskFactory,
            signals: [.code(500)],
            policy: .upToAttempts(count: 3),
            delay: .exponential(interval: 0.1, attempt: 1, base: 2)
        )
        
        var callCount = 0
        let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
            callCount += 1
            return (HTTPResponse(status: .internalServerError), nil) // Always return 500
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
        XCTAssertEqual(callCount, 3) // Should try 3 times total
        XCTAssertEqual(response.status, .internalServerError)
    }
    
    func testRetryOnThrownError() async throws {
        // Given
        let middleware = RetryingMiddleware(
            logger: infrastructure.logger,
            taskFactory: infrastructure.taskFactory,
            signals: [.errorThrown],
            policy: .upToAttempts(count: 3),
            delay: .exponential(interval: 0.1, attempt: 1, base: 2)
        )
        
        var callCount = 0
        let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
            callCount += 1
            if callCount == 1 {
                throw URLError(.notConnectedToInternet)
            }
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
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(response.status, .ok)
    }
} 
