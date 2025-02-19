import HTTPTypes
import Logging
import TestInfrastructure
import Api
import OpenAPIRuntime
import Foundation
import Testing
@testable import DefaultApiImplementation

@Suite("RetryMiddleware Tests")
struct RetryMiddlewareTests {
    @Test("Successful request without retry")
    func successfulRequestWithoutRetry() async throws {
        let infrastructure = TestInfrastructureLayer()
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
        
        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test",
            next: next
        )
        
        #expect(callCount == 1)
        #expect(response.status == .ok)
    }
    
    @Test("Non-retriable error")
    func nonRetriableError() async throws {
        let infrastructure = TestInfrastructureLayer()
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
            return (HTTPResponse(status: .badRequest), nil)
        }
        
        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test",
            next: next
        )
        
        #expect(callCount == 1)
        #expect(response.status == .badRequest)
    }
    
    @Test("Retriable error with success")
    func retriableErrorWithSuccess() async throws {
        let infrastructure = TestInfrastructureLayer()
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
                return (HTTPResponse(status: .internalServerError), nil)
            }
            return (HTTPResponse(status: .ok), nil)
        }
        
        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test",
            next: next
        )
        
        #expect(callCount == 2)
        #expect(response.status == .ok)
    }
    
    @Test("Retry on thrown error")
    func retryOnThrownError() async throws {
        let infrastructure = TestInfrastructureLayer()
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
        
        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test",
            next: next
        )
        
        #expect(callCount == 2)
        #expect(response.status == .ok)
    }
    
    @Test("Retriable error exhausts attempts")
    func retriableErrorExhaustsAttempts() async throws {
        let infrastructure = TestInfrastructureLayer()
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
            return (HTTPResponse(status: .internalServerError), nil)
        }
        
        let (response, _) = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.com", path: "/test"),
            body: nil,
            baseURL: URL(string: "https://example.com")!,
            operationID: "test",
            next: next
        )
        
        #expect(callCount == 3, "Should try exactly 3 times total")
        #expect(response.status == .internalServerError)
    }
} 
