import Testing
import Foundation
import TestInfrastructure
import Convenience
import Filesystem
import PersistentStorage
import AsyncExtensions
@testable import PersistentStorageSQLite

@Suite
struct UserStorageManagerTests {

    @Test
    func testCreateOnlyOnce() async throws {
        // given
        let infrastructure = TestInfrastructureLayer()
        let manager = try SqliteUserStorageManager(
            logger: infrastructure.logger,
            userDefaults: AsyncExtensions.Atomic(value: .standard),
            environment: .init(
                logger: infrastructure.logger,
                fileManager: infrastructure.fileManager,
                versionLabel: UUID().uuidString,
                containerDirectory: Foundation.FileManager.default
                    .temporaryDirectory
                    .appending(component: UUID().uuidString)
            )
        )
        let hostId = UUID().uuidString
        let deviceId = UUID().uuidString
        
        // when
        let _ = try await manager.create(
            hostId: hostId,
            deviceId: deviceId,
            refreshToken: "token",
            operations: []
        )
        
        do {
            let _ = try await manager.create(
                hostId: hostId,
                deviceId: deviceId,
                refreshToken: "token",
                operations: []
            )
            Issue.record()
        } catch {
            // then
            // Expected to throw
        }
    }
    
    @Test
    func testInvalidatorMarksForInvalidation() async throws {
        // given
        let infrastructure = TestInfrastructureLayer()
        let manager = try SqliteUserStorageManager(
            logger: infrastructure.logger,
            userDefaults: AsyncExtensions.Atomic(value: .standard),
            environment: .init(
                logger: infrastructure.logger,
                fileManager: infrastructure.fileManager,
                versionLabel: UUID().uuidString,
                containerDirectory: Foundation.FileManager.default
                    .temporaryDirectory
                    .appending(component: UUID().uuidString)
            )
        )
        let hostId = UUID().uuidString
        let deviceId = UUID().uuidString
        
        // when
        let _ = try await manager.create(
            hostId: hostId,
            deviceId: deviceId,
            refreshToken: "token",
            operations: []
        )
        let invalidator = await manager.invalidator(for: hostId)
        await invalidator()
        
        // then
        #expect(try await manager.items.isEmpty)
    }
    
    @Test
    func testItemsReturnsCreatedStorages() async throws {
        // given
        let infrastructure = TestInfrastructureLayer()
        let manager = try SqliteUserStorageManager(
            logger: infrastructure.logger,
            userDefaults: AsyncExtensions.Atomic(value: .standard),
            environment: .init(
                logger: infrastructure.logger,
                fileManager: infrastructure.fileManager,
                versionLabel: UUID().uuidString,
                containerDirectory: Foundation.FileManager.default
                    .temporaryDirectory
                    .appending(component: UUID().uuidString)
            )
        )
        let hostId1 = UUID().uuidString
        let hostId2 = UUID().uuidString
        let deviceId1 = UUID().uuidString
        let deviceId2 = UUID().uuidString
        
        // when
        let _ = try await manager.create(
            hostId: hostId1,
            deviceId: deviceId1,
            refreshToken: "token1",
            operations: []
        )
        let _ = try await manager.create(
            hostId: hostId2,
            deviceId: deviceId2,
            refreshToken: "token2",
            operations: []
        )
        
        // then
        let items = try await manager.items
        #expect(items.count == 2)
        #expect(items.contains { $0.hostId == hostId1 })
        #expect(items.contains { $0.hostId == hostId2 })
    }
    
    @Test
    func testStoragePreviewCanBeAwakened() async throws {
        // given
        let infrastructure = TestInfrastructureLayer()
        let manager = try SqliteUserStorageManager(
            logger: infrastructure.logger,
            userDefaults: AsyncExtensions.Atomic(value: .standard),
            environment: .init(
                logger: infrastructure.logger,
                fileManager: infrastructure.fileManager,
                versionLabel: UUID().uuidString,
                containerDirectory: Foundation.FileManager.default
                    .temporaryDirectory
                    .appending(component: UUID().uuidString)
            )
        )
        let hostId = UUID().uuidString
        let deviceId = UUID().uuidString
        
        // when
        let _ = try await manager.create(
            hostId: hostId,
            deviceId: deviceId,
            refreshToken: "token",
            operations: []
        )
        let items = try await manager.items
        let preview = items.first!
        
        // then
        let storage = try await preview.awake()
        #expect(storage is SQLiteUserStorage)
    }
    
    @Test
    func testDoesNotContainItemThatFailedToInvalidate() async throws {
        // given
        let infrastructureWithFailingRemove = modify(TestInfrastructureLayer()) {
            var manager = $0.testFileManager
            manager.removeItemBlock = { url throws(RemoveItemError) in
                throw RemoveItemError.internal(InternalError.error(""))
            }
            $0.testFileManager = manager
        }
        let manager = try SqliteUserStorageManager(
            logger: infrastructureWithFailingRemove.logger,
            userDefaults: AsyncExtensions.Atomic(value: .standard),
            environment: .init(
                logger: infrastructureWithFailingRemove.logger,
                fileManager: infrastructureWithFailingRemove.fileManager,
                versionLabel: UUID().uuidString,
                containerDirectory: Foundation.FileManager.default
                    .temporaryDirectory
                    .appending(component: UUID().uuidString)
            )
        )
        let hostId = UUID().uuidString
        let deviceId = UUID().uuidString
        
        // when
        let _ = try await manager.create(
            hostId: hostId,
            deviceId: deviceId,
            refreshToken: "token",
            operations: []
        )
        let invalidator = await manager.invalidator(for: hostId)
        await invalidator()
        
        // then
        #expect(try await manager.items.isEmpty)
    }
    
    @Test
    func testDoesNotContainItemWithNamesThatDontMatchFormat() async throws {
        // given
        let infrastructureWithFailingRemove = modify(TestInfrastructureLayer()) {
            let manager = $0.testFileManager
            var mutableManager = $0.testFileManager
            mutableManager.listDirectoryBlock = { url, mask throws(ListDirectoryError) in
                let result = try manager.listDirectory(at: url, mask: mask)
                return result + [url.appending(component: "bla bla")]
            }
            $0.testFileManager = mutableManager
        }
        let manager = try SqliteUserStorageManager(
            logger: infrastructureWithFailingRemove.logger,
            userDefaults: AsyncExtensions.Atomic(value: .standard),
            environment: .init(
                logger: infrastructureWithFailingRemove.logger,
                fileManager: infrastructureWithFailingRemove.fileManager,
                versionLabel: UUID().uuidString,
                containerDirectory: Foundation.FileManager.default
                    .temporaryDirectory
                    .appending(component: UUID().uuidString)
            )
        )
        
        // then
        #expect(try await manager.items.isEmpty)
    }
    
    @Test
    func testStoragePreservesDeviceId() async throws {
        // given
        let infrastructure = TestInfrastructureLayer()
        let manager = try SqliteUserStorageManager(
            logger: infrastructure.logger,
            userDefaults: AsyncExtensions.Atomic(value: .standard),
            environment: .init(
                logger: infrastructure.logger,
                fileManager: infrastructure.fileManager,
                versionLabel: UUID().uuidString,
                containerDirectory: Foundation.FileManager.default
                    .temporaryDirectory
                    .appending(component: UUID().uuidString)
            )
        )
        let hostId = UUID().uuidString
        let deviceId = UUID().uuidString
        
        // when
        let storage = try await manager.create(
            hostId: hostId,
            deviceId: deviceId,
            refreshToken: "token",
            operations: []
        )
        
        // then
        let retrievedDeviceId = await storage.deviceId
        #expect(retrievedDeviceId == deviceId)
    }
    
    @Test
    func testDeviceIdPersistedAfterReawakening() async throws {
        // given
        let infrastructure = TestInfrastructureLayer()
        let manager = try SqliteUserStorageManager(
            logger: infrastructure.logger,
            userDefaults: AsyncExtensions.Atomic(value: .standard),
            environment: .init(
                logger: infrastructure.logger,
                fileManager: infrastructure.fileManager,
                versionLabel: UUID().uuidString,
                containerDirectory: Foundation.FileManager.default
                    .temporaryDirectory
                    .appending(component: UUID().uuidString)
            )
        )
        let hostId = UUID().uuidString
        let deviceId = UUID().uuidString
        
        // when
        let _ = try await manager.create(
            hostId: hostId,
            deviceId: deviceId,
            refreshToken: "token",
            operations: []
        )
        
        let items = try await manager.items
        let preview = items.first!
        let reawokenStorage = try await preview.awake()
        
        // then
        let retrievedDeviceId = await reawokenStorage.deviceId
        #expect(retrievedDeviceId == deviceId)
    }
}
