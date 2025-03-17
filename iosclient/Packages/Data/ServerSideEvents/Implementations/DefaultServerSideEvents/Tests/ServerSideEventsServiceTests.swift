import HTTPTypes
import Logging
import TestInfrastructure
import Api
import Foundation
import Testing
import ServerSideEvents
@testable import DefaultServerSideEvents

@Suite("ServerSideEventsService Tests", .serialized)
struct ServerSideEventsServiceTests {
    @Test("Successfully starts and stops service")
    func successfullyStartsAndStops() async throws {
        let infrastructure = TestInfrastructureLayer()
        
        let service = ServerSideEventsService(
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger,
            urlConfigurationFactory: {
                DefaultUrlConfiguration(endpoint: URL(string: "https://example.com")!)
            },
            chunkCollectorFactory: {
                DefaultChunkCollector(logger: infrastructure.logger)
            },
            eventParserFactory: {
                DefaultEventParser(logger: infrastructure.logger)
            },
            refreshTokenMiddleware: MockAuthMiddleware()
        )
        
        await service.start()
        await service.stop()
    }
    
    @Test("Handles missing auth middleware")
    func handlesMissingAuthMiddleware() async throws {
        let infrastructure = TestInfrastructureLayer()
        
        let service = ServerSideEventsService(
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger,
            urlConfigurationFactory: {
                DefaultUrlConfiguration(endpoint: URL(string: "https://example.com")!)
            },
            chunkCollectorFactory: {
                DefaultChunkCollector(logger: infrastructure.logger)
            },
            eventParserFactory: {
                DefaultEventParser(logger: infrastructure.logger)
            },
            refreshTokenMiddleware: nil
        )
        
        await service.start()
        // Service should not start without auth middleware
        await service.stop()
    }
}

private struct MockAuthMiddleware: AuthMiddleware {
    
    func intercept<E>(routine: @escaping (String?) async -> Result<Void, E>) async throws {
        let result = await routine("mock-token")
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
} 
