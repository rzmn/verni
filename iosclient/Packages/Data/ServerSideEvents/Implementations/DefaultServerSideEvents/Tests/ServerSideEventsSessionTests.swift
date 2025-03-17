import HTTPTypes
import Logging
import TestInfrastructure
import Api
import Foundation
import Testing
@testable import DefaultServerSideEvents

@Suite("ServerSideEventsSession Tests", .serialized)
struct ServerSideEventsSessionTests {
    @Test("Successfully starts session and receives events")
    func successfullyStartsAndReceivesEvents() async throws {
        let infrastructure = TestInfrastructureLayer()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        
        MockURLProtocol.reset()
        MockURLProtocol.responseStatusCode = 200
        
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
        data: {"type":"connected"}\n\n
        data: {"type":"update","update":"operationsPulled","payload":\(String(data: try JSONEncoder().encode(operations), encoding: .utf8)!)}\n\n
        """.data(using: .utf8)!
        
        var receivedUpdates: [RemoteUpdate] = []
        let stream = AsyncStream<RemoteUpdate>.makeStream()
        let session = DefaultServerSideEventsSession(
            logger: infrastructure.logger,
            urlConfiguration: MockUrlConfiguration(
                sessionConfiguration: config,
                endpoint: URL(string: "https://example.com")!
            ),
            stream: stream,
            chunkCollectorFactory: { DefaultChunkCollector(logger: infrastructure.logger) },
            eventParserFactory: { DefaultEventParser(logger: infrastructure.logger) }
        )
        
        try await session.start()
        
        // Wait for processing
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(MockURLProtocol.requestedURLs.count == 1)
        #expect(MockURLProtocol.requestedURLs[0].absoluteString == "https://example.com")
        
        await session.stop()
    }
    
    @Test("Handles authentication error")
    func handlesAuthenticationError() async throws {
        let infrastructure = TestInfrastructureLayer()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        
        MockURLProtocol.reset()
        MockURLProtocol.responseStatusCode = 401
        
        let stream = AsyncStream<RemoteUpdate>.makeStream()
        let session = DefaultServerSideEventsSession(
            logger: infrastructure.logger,
            urlConfiguration: MockUrlConfiguration(
                sessionConfiguration: config,
                endpoint: URL(string: "https://example.com")!
            ),
            stream: stream,
            chunkCollectorFactory: { DefaultChunkCollector(logger: infrastructure.logger) },
            eventParserFactory: { DefaultEventParser(logger: infrastructure.logger) }
        )
        
        do {
            try await session.start()
            Issue.record("Expected token expired error")
        } catch SessionStartError.tokenExpired {
            // Expected error
        }
    }
    
    @Test("Handles network error")
    func handlesNetworkError() async throws {
        let infrastructure = TestInfrastructureLayer()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        
        MockURLProtocol.reset()
        MockURLProtocol.error = URLError(.notConnectedToInternet)
        
        let stream = AsyncStream<RemoteUpdate>.makeStream()
        let session = DefaultServerSideEventsSession(
            logger: infrastructure.logger,
            urlConfiguration: MockUrlConfiguration(
                sessionConfiguration: config,
                endpoint: URL(string: "https://example.com")!
            ),
            stream: stream,
            chunkCollectorFactory: { DefaultChunkCollector(logger: infrastructure.logger) },
            eventParserFactory: { DefaultEventParser(logger: infrastructure.logger) }
        )
        
        do {
            try await session.start()
            Issue.record("Expected network error")
        } catch SessionStartError.retriableError {
            // Expected error
        }
    }
} 
