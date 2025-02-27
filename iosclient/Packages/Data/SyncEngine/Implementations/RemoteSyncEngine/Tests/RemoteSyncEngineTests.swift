import Testing
import SyncEngine
import Api
import Logging
import PersistentStorage
import AsyncExtensions
import TestInfrastructure
import Convenience
import MockApiImplementation
@testable import RemoteSyncEngine

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

@Suite("RemoteSyncEngine Tests")
struct RemoteSyncEngineTests {
    final class MockUserStorage: @unchecked Sendable, UserStorage {
        var userId: HostId { "userId" }
        var deviceId: DeviceId { "deviceId" }
        var refreshToken: String { "refreshToken" }
        
        var storedOperations: [Operation] = []
        var shouldFailUpdate = false
        var updateError: Error?
        var updateCallCount = 0
        
        func close() async {}
        func invalidate() async {}
        func update(refreshToken: String) async throws {}
        
        var operations: [Operation] {
            get async {
                storedOperations
            }
        }
        
        func update(operations: [Operation]) async throws {
            updateCallCount += 1
            if shouldFailUpdate {
                if let error = updateError {
                    throw error
                }
                throw InternalError.error("test")
            }
            storedOperations = operations
        }
    }
    
    final class MockRemoteUpdatesService: @unchecked Sendable, RemoteUpdatesService {
        let eventPublisher = EventPublisher<RemoteUpdate>()
        var startCallCount = 0
        
        var eventSource: any EventSource<RemoteUpdate> {
            eventPublisher
        }
        
        func start() async {
            startCallCount += 1
        }
        
        func stop() async {}
    }
    
    final class OperationsObserver: @unchecked Sendable {
        var receivedOperations: [Components.Schemas.SomeOperation] = []
        
        func handleOperations(_ operations: [Components.Schemas.SomeOperation]) {
            receivedOperations = operations
        }
    }
    
    @Test("Push operations to remote")
    func pushOperationsToRemote() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let storage = MockUserStorage()
        let api = MockApi()
        let updates = MockRemoteUpdatesService()
        
        let factory = RemoteSyncEngineFactory(
            api: api,
            updates: updates,
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
        #expect(storage.updateCallCount == 2) // Initial store + synced update
        #expect(api.pushOperationsCallCount == 1)
        #expect(api.pushedOperations.count == 1)
        #expect(api.pushedOperations[0].base.operationId == "1")
        
        let storedOperations = await storage.operations
        #expect(storedOperations.count == 1)
        #expect(storedOperations[0].kind == .synced)
        #expect(storedOperations[0].payload.base.operationId == "1")
        
        #expect(observer.receivedOperations.count == 1)
        #expect(observer.receivedOperations[0].base.operationId == "1")
    }
    
    @Test("Handle remote updates")
    func handleRemoteUpdates() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let storage = MockUserStorage()
        let api = MockApi()
        let updates = MockRemoteUpdatesService()
        
        let factory = RemoteSyncEngineFactory(
            api: api,
            updates: updates,
            storage: storage,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        let engine = await factory.create()
        
        let observer = OperationsObserver()
        await (await engine.updates).subscribeWeak(observer) { operations in
            observer.handleOperations(operations)
        }
        
        let remoteOperations: [Components.Schemas.SomeOperation] = [
            .init(id: "1", author: "remote")
        ]
        
        // When
        await updates.eventPublisher.notify(.newOperationsAvailable(remoteOperations))
        try await infrastructure.testTaskFactory.runUntilIdle()
        
        // Then
        #expect(storage.updateCallCount == 2) // Initial store + confirmed update
        #expect(api.confirmOperationsCallCount == 1)
        #expect(api.confirmedOperationIds == ["1"])
        
        let storedOperations = await storage.operations
        #expect(storedOperations.count == 1)
        #expect(storedOperations[0].kind == .synced)
        #expect(storedOperations[0].payload.base.operationId == "1")
        
        #expect(observer.receivedOperations.count == 1)
        #expect(observer.receivedOperations[0].base.operationId == "1")
    }
    
    @Test("Push operation failure")
    func pushOperationFailure() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let storage = MockUserStorage()
        let api = MockApi()
        api.shouldFailRequest = true
        let updates = MockRemoteUpdatesService()
        
        let factory = RemoteSyncEngineFactory(
            api: api,
            updates: updates,
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
        #expect(storage.updateCallCount == 1) // Only initial store
        #expect(api.pushOperationsCallCount == 1)
        
        let storedOperations = await storage.operations
        #expect(storedOperations.count == 1)
        #expect(storedOperations[0].kind == .pendingSync)
        
        #expect(observer.receivedOperations.count == 1)
        #expect(observer.receivedOperations[0].base.operationId == "1")
    }
    
    @Test("Confirm operation failure")
    func confirmOperationFailure() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let storage = MockUserStorage()
        let api = MockApi()
        api.shouldFailRequest = true
        let updates = MockRemoteUpdatesService()
        
        let factory = RemoteSyncEngineFactory(
            api: api,
            updates: updates,
            storage: storage,
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger
        )
        let engine = await factory.create()
        
        let observer = OperationsObserver()
        await (await engine.updates).subscribeWeak(observer) { operations in
            observer.handleOperations(operations)
        }
        
        let remoteOperations: [Components.Schemas.SomeOperation] = [
            .init(id: "1", author: "remote")
        ]
        
        // When
        await updates.eventPublisher.notify(.newOperationsAvailable(remoteOperations))
        try await infrastructure.testTaskFactory.runUntilIdle()
        
        // Then
        #expect(storage.updateCallCount == 1) // Only initial store
        #expect(api.confirmOperationsCallCount == 1)
        
        let storedOperations = await storage.operations
        #expect(storedOperations.count == 1)
        #expect(storedOperations[0].kind == .pendingConfirm)
        
        #expect(observer.receivedOperations.count == 1)
        #expect(observer.receivedOperations[0].base.operationId == "1")
    }
}
