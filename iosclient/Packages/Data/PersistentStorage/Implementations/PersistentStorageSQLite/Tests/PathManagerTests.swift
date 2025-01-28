import Testing
import Foundation
import TestInfrastructure
import Base
import Filesystem
@testable import PersistentStorageSQLite

@Suite
struct PathManagerTests {

    @Test
    func testCreateOnlyOnce() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let manager = try! await SqliteDbPathManager(
            logger: infrastructure.logger,
            containerDirectory: Foundation.FileManager.default
                .temporaryDirectory
                .appending(component: UUID().uuidString),
            versionLabel: UUID().uuidString,
            pathManager: infrastructure.fileManager
        )
        let host = UUID().uuidString

        // when

        let _ = try await manager.create(id: host)
        do {
            let _ = try await manager.create(id: host)
            Issue.record()
        } catch {

            // then
        }
    }

    @Test
    func testFailedToCreateIfFailedToInvalidate() async throws {

        // given

        let infrastructureWithFailingRemove = modify(TestInfrastructureLayer()) {
            var manager = $0.testFileManager
            manager.removeItemBlock = { url throws(RemoveItemError) in
                throw RemoveItemError.internal(InternalError.error(""))
            }
            $0.testFileManager = manager
        }
        let containerDirectory = Foundation.FileManager.default
            .temporaryDirectory
            .appending(component: UUID().uuidString)
        let manager = try! await SqliteDbPathManager(
            logger: infrastructureWithFailingRemove.logger,
            containerDirectory: containerDirectory,
            versionLabel: UUID().uuidString,
            pathManager: infrastructureWithFailingRemove.fileManager
        )
        let host = UUID().uuidString

        // when

        let _ = try await manager.create(id: host)
        await manager.invalidate(id: host)
        do {
            let _ = try await manager.create(id: host)
            Issue.record()
        } catch {
            // then
        }
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
        let containerDirectory = Foundation.FileManager.default
            .temporaryDirectory
            .appending(component: UUID().uuidString)
        let manager = try! await SqliteDbPathManager(
            logger: infrastructureWithFailingRemove.logger,
            containerDirectory: containerDirectory,
            versionLabel: UUID().uuidString,
            pathManager: infrastructureWithFailingRemove.fileManager
        )
        let host = UUID().uuidString

        // when

        let _ = try await manager.create(id: host)
        await manager.invalidate(id: host)

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
        let containerDirectory = Foundation.FileManager.default
            .temporaryDirectory
            .appending(component: UUID().uuidString)
        let manager = try! await SqliteDbPathManager(
            logger: infrastructureWithFailingRemove.logger,
            containerDirectory: containerDirectory,
            versionLabel: UUID().uuidString,
            pathManager: infrastructureWithFailingRemove.fileManager
        )

        // when

        // then

        #expect(try await manager.items.isEmpty)
    }
}
