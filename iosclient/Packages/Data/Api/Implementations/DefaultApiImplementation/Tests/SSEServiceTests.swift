//
//  SSEServiceTests.swift
//  DefaultApiImplementation
//
//  Created by Никита Разумный on 2/19/25.
//

import HTTPTypes
import Logging
import TestInfrastructure
import Api
import OpenAPIRuntime
import Foundation
import Testing
import AsyncExtensions
@testable import DefaultApiImplementation

private class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseData: Data?
    nonisolated(unsafe) static var responseStatusCode: Int = 200
    nonisolated(unsafe) static var error: Error?
    nonisolated(unsafe) static var requestedURLs: [URL] = []
    
    static func reset() {
        responseData = nil
        responseStatusCode = 200
        error = nil
        requestedURLs = []
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let client = client else { return }
        
        if let url = request.url {
            Self.requestedURLs.append(url)
        }
        
        if let error = Self.error {
            client.urlProtocol(self, didFailWithError: error)
            return
        }
        
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: Self.responseStatusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        
        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        
        if let data = Self.responseData {
            client.urlProtocol(self, didLoad: data)
        }
        
        client.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

@Suite("SSEService Tests", .serialized)
struct SSEServiceTests {
    @Test("Successfully connects and receives operations")
    func successfullyConnectsAndReceivesOperations() async throws {
        let infrastructure = TestInfrastructureLayer()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        MockURLProtocol.reset()
        
        // Prepare mock response
        let operations = [
            Components.Schemas.SomeOperation(
                value1: Components.Schemas.BaseOperation(
                    operationId: "operationId",
                    createdAt: 123,
                    authorId: "authorId"
                ),
                value2: .CreateUserOperation(
                    .init(
                        createUser: .init(
                            userId: "userId",
                            displayName: "displayName"
                        )
                    )
                )
            )
        ]
        MockURLProtocol.responseData = """
        data: \(String(data: try JSONEncoder().encode(operations), encoding: .utf8)!)\n\n
        """.data(using: .utf8)!
        
        let service = await SSEService(
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger,
            endpoint: URL(string: "https://example.com")!,
            session: session
        )
        
        nonisolated(unsafe) var receivedUpdates: [RemoteUpdate] = []
        await service.eventSource.subscribeWeak(service) { update in
            receivedUpdates.append(update)
        }
        
        await service.start()
        
        // Wait for processing
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(MockURLProtocol.requestedURLs.count == 1)
        #expect(MockURLProtocol.requestedURLs[0].absoluteString == "https://example.com/operationsQueue")
        #expect(receivedUpdates.count == 1)
        
        if case .newOperationsAvailable(let receivedOperations) = receivedUpdates[0] {
            #expect(receivedOperations.count == operations.count)
        } else {
            Issue.record("unexpected update type received")
        }
        
        await service.stop()
    }
    
    @Test("Handles invalid response status code")
    func handlesInvalidResponseStatusCode() async throws {
        let infrastructure = TestInfrastructureLayer()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        MockURLProtocol.reset()
        MockURLProtocol.responseStatusCode = 404
        
        let service = await SSEService(
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger,
            endpoint: URL(string: "https://example.com")!,
            session: session
        )
        
        nonisolated(unsafe) var receivedUpdates: [RemoteUpdate] = []
        await service.eventSource.subscribeWeak(service) { update in
            receivedUpdates.append(update)
        }
        
        await service.start()
        
        // Wait for processing
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(MockURLProtocol.requestedURLs.count == 1)
        #expect(receivedUpdates.isEmpty)
        
        await service.stop()
    }
    
    @Test("Handles network error")
    func handlesNetworkError() async throws {
        let infrastructure = TestInfrastructureLayer()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        MockURLProtocol.reset()
        MockURLProtocol.error = URLError(.notConnectedToInternet)
        
        let service = await SSEService(
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger,
            endpoint: URL(string: "https://example.com")!,
            session: session
        )
        
        nonisolated(unsafe) var receivedUpdates: [RemoteUpdate] = []
        await service.eventSource.subscribeWeak(service) { update in
            receivedUpdates.append(update)
        }
        
        await service.start()
        
        // Wait for processing
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(MockURLProtocol.requestedURLs.count == 1)
        #expect(receivedUpdates.isEmpty)
        
        await service.stop()
    }
    
    @Test("Handles malformed data")
    func handlesMalformedData() async throws {
        let infrastructure = TestInfrastructureLayer()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        MockURLProtocol.reset()
        MockURLProtocol.responseData = """
        data: {"invalid": "json"}\n\n
        """.data(using: .utf8)!
        
        let service = await SSEService(
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger,
            endpoint: URL(string: "https://example.com")!,
            session: session
        )
        
        nonisolated(unsafe) var receivedUpdates: [RemoteUpdate] = []
        await service.eventSource.subscribeWeak(service) { update in
            receivedUpdates.append(update)
        }
        
        await service.start()
        
        // Wait for processing
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(receivedUpdates.isEmpty)
        
        await service.stop()
    }
}
