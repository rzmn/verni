import Testing
import Logging
import Foundation
import Entities
import Api
import Convenience
import AsyncExtensions
import TestInfrastructure
import SyncEngine
import Filesystem
import AvatarsRepository
@testable import DefaultAvatarsRepositoryImplementation

final class MockAPI: @unchecked Sendable, APIProtocol {
    var avatars: [String: Components.Schemas.Image] = [:]
    var shouldFailGetAvatars = false
    var getAvatarsCallCount = 0
    
    func getAvatars(_ input: Operations.GetAvatars.Input) async throws -> Operations.GetAvatars.Output {
        getAvatarsCallCount += 1
        if shouldFailGetAvatars {
            return .internalServerError(.init(body: .json(.init(error: .init(reason: ._internal)))))
        }
        let requestedIds = input.query.ids
        let response = avatars.filter { requestedIds.contains($0.key) }
        return .ok(.init(body: .json(.init(response: .init(additionalProperties: response)))))
    }
    
    // Implement other APIProtocol methods as needed...
    func signup(_ input: Operations.Signup.Input) async throws -> Operations.Signup.Output { fatalError() }
    func login(_ input: Operations.Login.Input) async throws -> Operations.Login.Output { fatalError() }
    func refreshSession(_ input: Operations.RefreshSession.Input) async throws -> Operations.RefreshSession.Output { fatalError() }
    func updateEmail(_ input: Operations.UpdateEmail.Input) async throws -> Operations.UpdateEmail.Output { fatalError() }
    func updatePassword(_ input: Operations.UpdatePassword.Input) async throws -> Operations.UpdatePassword.Output { fatalError() }
    func registerForPushNotifications(_ input: Operations.RegisterForPushNotifications.Input) async throws -> Operations.RegisterForPushNotifications.Output { fatalError() }
    func searchUsers(_ input: Operations.SearchUsers.Input) async throws -> Operations.SearchUsers.Output { fatalError() }
    func confirmEmail(_ input: Operations.ConfirmEmail.Input) async throws -> Operations.ConfirmEmail.Output { fatalError() }
    func sendEmailConfirmationCode(_ input: Operations.SendEmailConfirmationCode.Input) async throws -> Operations.SendEmailConfirmationCode.Output { fatalError() }
    func pullOperations(_ input: Operations.PullOperations.Input) async throws -> Operations.PullOperations.Output { fatalError() }
    func pushOperations(_ input: Operations.PushOperations.Input) async throws -> Operations.PushOperations.Output { fatalError() }
    func confirmOperations(_ input: Operations.ConfirmOperations.Input) async throws -> Operations.ConfirmOperations.Output { fatalError() }
}

@Suite("DefaultAvatarsRepository Tests")
struct AvatarsRepositoryTests {
    final class MockSyncEngine: @unchecked Sendable, Engine {
        let eventPublisher = EventPublisher<[Components.Schemas.SomeOperation]>()
        var storedOperations: [Components.Schemas.SomeOperation] = []
        var pushCallCount = 0
        var shouldFailPush = false
        
        var updates: any EventSource<[Components.Schemas.SomeOperation]> {
            get async { eventPublisher }
        }
        
        var operations: [Components.Schemas.SomeOperation] {
            get async { storedOperations }
        }
        
        func push(operations: [Components.Schemas.SomeOperation]) async throws {
            pushCallCount += 1
            if shouldFailPush {
                throw InternalError.error("test")
            }
            storedOperations.append(contentsOf: operations)
            await eventPublisher.notify(operations)
        }
    }
    
    @Test("Upload image")
    func uploadImage() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let sync = MockSyncEngine()
        let userId = "testUser"
        
        let repository = await DefaultAvatarsRepository(
            userId: userId,
            sync: sync,
            infrastructure: infrastructure,
            logger: infrastructure.logger
        )
        
        let imageData = "base64Data"
        nonisolated(unsafe) var receivedUpdates: [Image.Identifier: Image] = [:]
        
        await repository.updates.subscribeWeak(repository) { updates in
            receivedUpdates = updates
        }
        
        // When
        let imageId = try await repository.upload(image: imageData)
        
        // Then
        #expect(sync.pushCallCount == 1)
        #expect(sync.storedOperations.count == 1)
        let operation = sync.storedOperations[0]
        
        #expect(operation.value1.authorId == userId)
        if case .UploadImageOperation(let payload) = operation.value2 {
            #expect(payload.uploadImage.imageId == imageId)
            #expect(payload.uploadImage.base64 == imageData)
        } else {
            throw InternalError.error("Wrong operation type")
        }
        
        #expect(receivedUpdates.count == 1)
        #expect(receivedUpdates[imageId]?.base64 == imageData)
        
        let storedImage = await repository[imageId]
        #expect(storedImage?.base64 == imageData)
    }
    
    @Test("Upload image failure")
    func uploadImageFailure() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let sync = MockSyncEngine()
        sync.shouldFailPush = true
        
        let repository = await DefaultAvatarsRepository(
            userId: "testUser",
            sync: sync,
            infrastructure: infrastructure,
            logger: infrastructure.logger
        )
        
        // When/Then
        do {
            _ = try await repository.upload(image: "data")
            throw InternalError.error("Should have failed")
        } catch is UploadImageError {
            // Expected error
        }
    }
}

@Suite("DefaultAvatarsRemoteDataSource Tests")
struct AvatarsRemoteDataSourceTests {
    @Test("Fetch avatars with cache")
    func fetchAvatarsWithCache() async throws {
        // Given
        var infrastructure = TestInfrastructureLayer()
        let api = MockAPI()
        
        nonisolated(unsafe) var storedFiles: [URL: Data] = [:]
        infrastructure.testFileManager.createDirectoryBlock = { _ in true }
        infrastructure.testFileManager.createFileWithDataBlock = { url, data in
            storedFiles[url] = data
        }
        infrastructure.testFileManager.readFileBlock = { url throws(ReadFileError) in
            guard let data = storedFiles[url] else {
                throw ReadFileError.noSuchFile
            }
            return data
        }
        
        let imageId = "test1"
        let imageData = "testData"
        api.avatars = [
            imageId: .init(id: imageId, base64: imageData)
        ]
        
        let dataSource = DefaultAvatarsRemoteDataSource(
            logger: infrastructure.logger,
            fileManager: infrastructure.fileManager,
            taskFactory: infrastructure.taskFactory,
            api: api
        )
        
        // When
        let result1 = await dataSource.fetch(ids: [imageId])
        let result2 = await dataSource.fetch(ids: [imageId])
        try await infrastructure.testTaskFactory.runUntilIdle()
        
        // Then
        #expect(api.getAvatarsCallCount == 1) // Should use cache for second fetch
        #expect(result1[imageId]?.base64 == imageData)
        #expect(result2[imageId]?.base64 == imageData)
    }
    
    @Test("Fetch avatars API failure")
    func fetchAvatarsFailure() async throws {
        // Given
        let infrastructure = TestInfrastructureLayer()
        let api = MockAPI()
        api.shouldFailGetAvatars = true
        
        let dataSource = DefaultAvatarsRemoteDataSource(
            logger: infrastructure.logger,
            fileManager: infrastructure.fileManager,
            taskFactory: infrastructure.taskFactory,
            api: api
        )
        
        // When
        let result = await dataSource.fetch(ids: ["test1"])
        
        // Then
        #expect(result.isEmpty)
        #expect(api.getAvatarsCallCount == 1)
    }
    
    @Test("Fetch multiple avatars")
    func fetchMultipleAvatars() async throws {
        // Given
        var infrastructure = TestInfrastructureLayer()
        let api = MockAPI()
        
        nonisolated(unsafe) var storedFiles: [URL: Data] = [:]
        infrastructure.testFileManager.createDirectoryBlock = { _ in true }
        infrastructure.testFileManager.createFileWithDataBlock = { url, data in
            storedFiles[url] = data
        }
        infrastructure.testFileManager.readFileBlock = { url throws(ReadFileError) in
            guard let data = storedFiles[url] else {
                throw ReadFileError.noSuchFile
            }
            return data
        }
        
        let images = [
            "test1": "data1",
            "test2": "data2"
        ]
        api.avatars = images.reduce(into: [:]) { dict, element in
            let (id, data) = element
            dict[id] = .init(id: id, base64: data)
        }
        
        let dataSource = DefaultAvatarsRemoteDataSource(
            logger: infrastructure.logger,
            fileManager: infrastructure.fileManager,
            taskFactory: infrastructure.taskFactory,
            api: api
        )
        
        // When
        let result = await dataSource.fetch(ids: Array(images.keys))
        
        // Then
        #expect(api.getAvatarsCallCount == 1)
        #expect(result.count == 2)
        for (id, data) in images {
            #expect(result[id]?.base64 == data)
        }
    }
    
    @Test("Use cached image without API call")
    func useCachedImage() async throws {
        // Given
        var infrastructure = TestInfrastructureLayer()
        let api = MockAPI()
        
        let imageId = "test1"
        let imageData = "testData"
        
        // Setup file manager simulating pre-cached image
        infrastructure.testFileManager.createDirectoryBlock = { _ in true }
        infrastructure.testFileManager.createFileWithDataBlock = { url, data in }
        infrastructure.testFileManager.readFileBlock = { url throws(ReadFileError) in
            guard url.lastPathComponent.hasSuffix("\(imageId).base64") else {
                throw .noSuchFile
            }
            return Data(base64Encoded: imageData)!
        }
        
        let dataSource = DefaultAvatarsRemoteDataSource(
            logger: infrastructure.logger,
            fileManager: infrastructure.fileManager,
            taskFactory: infrastructure.taskFactory,
            api: api
        )
        
        // When
        let result = await dataSource.fetch(ids: [imageId])
        try await infrastructure.testTaskFactory.runUntilIdle()
        
        // Then
        #expect(api.getAvatarsCallCount == 0) // Should not call API since image was cached
        #expect(result[imageId]?.base64 == imageData) // Should return cached image
    }
}

