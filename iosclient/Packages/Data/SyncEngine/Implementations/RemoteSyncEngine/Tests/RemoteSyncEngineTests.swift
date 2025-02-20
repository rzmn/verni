import Testing
import SyncEngine
import Api
import Logging
import PersistentStorage
import AsyncExtensions
import TestInfrastructure
import Convenience
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
    
    final class MockAPI: @unchecked Sendable, APIProtocol {
        var pushOperationsCallCount = 0
        var confirmOperationsCallCount = 0
        var shouldFailPush = false
        var shouldFailConfirm = false
        var pushedOperations: [Components.Schemas.SomeOperation] = []
        var confirmedIds: [String] = []
        
        func pushOperations(_ input: Operations.PushOperations.Input) async throws -> Operations.PushOperations.Output {
            pushOperationsCallCount += 1
            if shouldFailPush {
                return .internalServerError(.init(body: .json(.init(error: .init(reason: ._internal)))))
            }
            switch input.body {
            case .json(let payload):
                pushedOperations = payload.operations
                return .ok(.init(body: .json(.init(response: payload.operations))))
            }
        }
        
        func confirmOperations(_ input: Operations.ConfirmOperations.Input) async throws -> Operations.ConfirmOperations.Output {
            confirmOperationsCallCount += 1
            if shouldFailConfirm {
                return .internalServerError(.init(body: .json(.init(error: .init(reason: ._internal)))))
            }
            confirmedIds = input.query.ids
            return .ok(.init(body: .json(.init(response: .init()))))
        }
        
        // Implement other APIProtocol methods as needed...
        func signup(_ input: Operations.Signup.Input) async throws -> Operations.Signup.Output { fatalError() }
        func login(_ input: Operations.Login.Input) async throws -> Operations.Login.Output { fatalError() }
        func refreshSession(_ input: Operations.RefreshSession.Input) async throws -> Operations.RefreshSession.Output { fatalError() }
        func updateEmail(_ input: Operations.UpdateEmail.Input) async throws -> Operations.UpdateEmail.Output { fatalError() }
        func updatePassword(_ input: Operations.UpdatePassword.Input) async throws -> Operations.UpdatePassword.Output { fatalError() }
        func registerForPushNotifications(_ input: Operations.RegisterForPushNotifications.Input) async throws -> Operations.RegisterForPushNotifications.Output { fatalError() }
        func getAvatars(_ input: Operations.GetAvatars.Input) async throws -> Operations.GetAvatars.Output { fatalError() }
        func searchUsers(_ input: Operations.SearchUsers.Input) async throws -> Operations.SearchUsers.Output { fatalError() }
        func confirmEmail(_ input: Operations.ConfirmEmail.Input) async throws -> Operations.ConfirmEmail.Output { fatalError() }
        func sendEmailConfirmationCode(_ input: Operations.SendEmailConfirmationCode.Input) async throws -> Operations.SendEmailConfirmationCode.Output { fatalError() }
        func pullOperations(_ input: Operations.PullOperations.Input) async throws -> Operations.PullOperations.Output { fatalError() }
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
        let api = MockAPI()
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
        let api = MockAPI()
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
        #expect(api.confirmedIds == ["1"])
        
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
        let api = MockAPI()
        api.shouldFailPush = true
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
        let api = MockAPI()
        api.shouldFailConfirm = true
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
