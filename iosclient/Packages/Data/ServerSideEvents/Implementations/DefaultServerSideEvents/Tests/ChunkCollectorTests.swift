import HTTPTypes
import Logging
import TestInfrastructure
import Api
import Foundation
import Testing
@testable import DefaultServerSideEvents

@Suite("ChunkCollector Tests")
struct ChunkCollectorTests {
    @Test("Successfully collects complete message")
    func collectsCompleteMessage() async throws {
        let infrastructure = TestInfrastructureLayer()
        let collector = DefaultChunkCollector(
            logger: infrastructure.logger
        )
        
        let testData = "data: test message\n\n".data(using: .utf8)!
        let states = await collector.onDataReceived(testData)
        
        #expect(states.count == 1)
        if case .completed(let message) = states[0] {
            #expect(message == "test message")
        } else {
            Issue.record("Expected completed state")
        }
    }
    
    @Test("Handles incomplete message")
    func handlesIncompleteMessage() async throws {
        let infrastructure = TestInfrastructureLayer()
        let collector = DefaultChunkCollector(
            logger: infrastructure.logger
        )
        
        let partialData = "data: test".data(using: .utf8)!
        let states = await collector.onDataReceived(partialData)
        
        #expect(states.count == 1)
        if case .incomplete(let message) = states[0] {
            #expect(message == "test")
        } else {
            Issue.record("Expected incomplete state")
        }
    }
    
    @Test("Handles multiple messages")
    func handlesMultipleMessages() async throws {
        let infrastructure = TestInfrastructureLayer()
        let collector = DefaultChunkCollector(
            logger: infrastructure.logger
        )
        
        let testData = "data: message1\n\ndata: message2\n\n".data(using: .utf8)!
        let states = await collector.onDataReceived(testData)
        
        #expect(states.count == 2)
        if case .completed(let message1) = states[0] {
            #expect(message1 == "message1")
        }
        if case .completed(let message2) = states[1] {
            #expect(message2 == "message2")
        }
    }
} 
