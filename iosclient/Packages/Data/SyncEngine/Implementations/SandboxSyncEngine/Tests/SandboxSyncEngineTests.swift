import Testing
import SyncEngine
import Api
import Logging
import PersistentStorage
import AsyncExtensions
import TestInfrastructure
import Convenience
@testable import SandboxSyncEngine

private extension Components.Schemas.SomeOperation {
    init(id: String, author: String) {
        self = .init(
            value1: .init(operationId: id, createdAt: 123, authorId: author),
            value2: .BindUserOperation(
                .init(bindUser: .init(oldId: "123", newId: "345"))
            )
        )
    }
}

@Suite("SandboxSyncEngine Tests")
struct SandboxSyncEngineTests {
    final class MockSandboxStorage: @unchecked Sendable, SandboxStorage {
        var storedOperations: [Components.Schemas.SomeOperation] = []
        var shouldFailUpdate = false
        var updateError: Error?
        var updateCallCount = 0
        
        func close() async {}
        func invalidate() async {}
        
        var operations: [Components.Schemas.SomeOperation] {
            get async {
                storedOperations
            }
        }
        
        func update(operations: [Components.Schemas.SomeOperation]) async throws {
            updateCallCount += 1
            if shouldFailUpdate {
                if let error = updateError {
                    throw error
                }
                throw InternalError.error("test")
            }
            storedOperations.append(contentsOf: operations)
        }
    }
    
    final class OperationsObserver: @unchecked Sendable {
        var receivedOperations: [Components.Schemas.SomeOperation] = []
        
        func handleOperations(_ operations: [Components.Schemas.SomeOperation]) {
            receivedOperations = operations
        }
    }
    
    @Test("Get operations from storage")
    func getOperationsFromStorage() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let storage = MockSandboxStorage()
        let expectedOperations: [Components.Schemas.SomeOperation] = [
            .init(id: "1", author: "test"),
            .init(id: "2", author: "test")
        ]
        storage.storedOperations = expectedOperations
        
        let factory = SandboxSyncEngineFactory(
            storage: storage,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        let engine = await factory.create()
        
        // When
        let operations = await engine.operations
        
        // Then
        #expect(operations.count == 2)
        #expect(operations[0].base.operationId == "1")
        #expect(operations[1].base.operationId == "2")
    }
    
    @Test("Push operations to storage and notify subscribers")
    func pushOperationsAndNotify() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let storage = MockSandboxStorage()
        let factory = SandboxSyncEngineFactory(
            storage: storage,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        let engine = await factory.create()
        
        let observer = OperationsObserver()
        await (await engine.updates).subscribeWeak(observer) { operations in
            observer.handleOperations(operations)
        }
        
        let operationsToPush: [Components.Schemas.SomeOperation] = [
            .init(id: "1", author: "test")
        ]
        
        // When
        try await engine.push(operations: operationsToPush)
        
        // Then
        // Check storage update
        #expect(storage.updateCallCount == 1)
        let storedOperations = await storage.operations
        #expect(storedOperations.count == 1)
        #expect(storedOperations[0].base.operationId == "1")
        
        // Check notification
        #expect(observer.receivedOperations.count == 1)
        #expect(observer.receivedOperations[0].base.operationId == "1")
    }
    
    @Test("Storage update failure")
    func storageUpdateFailure() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let storage = MockSandboxStorage()
        storage.shouldFailUpdate = true
        let expectedError = InternalError.error("test")
        storage.updateError = expectedError
        
        let factory = SandboxSyncEngineFactory(
            storage: storage,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        let engine = await factory.create()
        
        let observer = OperationsObserver()
        await (await engine.updates).subscribeWeak(observer) { operations in
            observer.handleOperations(operations)
        }
        
        let operationsToPush: [Components.Schemas.SomeOperation] = [
            .init(id: "1", author: "test")
        ]
        
        // When
        var didThrow = false
        do {
            try await engine.push(operations: operationsToPush)
        } catch {
            didThrow = true
            #expect((error as? InternalError) == expectedError)
        }
        
        // Then
        #expect(didThrow == true, "Should throw an error")
        #expect(storage.updateCallCount == 1)
        let storedOperations = await storage.operations
        #expect(storedOperations.isEmpty)
        #expect(observer.receivedOperations.isEmpty, "Should not notify on failure")
    }
    
    @Test("Push single operation convenience method")
    func pushSingleOperation() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let storage = MockSandboxStorage()
        let factory = SandboxSyncEngineFactory(
            storage: storage,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        let engine = await factory.create()
        
        let observer = OperationsObserver()
        await (await engine.updates).subscribeWeak(observer) { operations in
            observer.handleOperations(operations)
        }
        
        let operation = Components.Schemas.SomeOperation(id: "1", author: "test")
        
        // When
        try await engine.push(operation: operation)
        
        // Then
        #expect(storage.updateCallCount == 1)
        let storedOperations = await storage.operations
        #expect(storedOperations.count == 1)
        #expect(storedOperations[0].base.operationId == "1")
        #expect(observer.receivedOperations.count == 1)
        #expect(observer.receivedOperations[0].base.operationId == "1")
    }
    
    @Test("Multiple subscribers receive updates")
    func multipleSubscribersReceiveUpdates() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let storage = MockSandboxStorage()
        let factory = SandboxSyncEngineFactory(
            storage: storage,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        let engine = await factory.create()
        
        let observer1 = OperationsObserver()
        let observer2 = OperationsObserver()
        
        await (await engine.updates).subscribeWeak(observer1) { operations in
            observer1.handleOperations(operations)
        }
        
        await (await engine.updates).subscribeWeak(observer2) { operations in
            observer2.handleOperations(operations)
        }
        
        let operationsToPush: [Components.Schemas.SomeOperation] = [
            .init(id: "1", author: "test")
        ]
        
        // When
        try await engine.push(operations: operationsToPush)
        
        // Then
        #expect(observer1.receivedOperations.count == 1)
        #expect(observer1.receivedOperations[0].base.operationId == "1")
        #expect(observer2.receivedOperations.count == 1)
        #expect(observer2.receivedOperations[0].base.operationId == "1")
    }
}

