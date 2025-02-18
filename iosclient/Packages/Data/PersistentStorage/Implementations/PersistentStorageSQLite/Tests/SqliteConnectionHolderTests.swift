import Testing
import Foundation
import TestInfrastructure
import Convenience
import Filesystem
import PersistentStorage
@testable import PersistentStorageSQLite
internal import SQLite

@Suite
struct SqliteConnectionHolderTests {
    
    @Test
    func testClosingNullsDatabase() async throws {
        // given
        let infrastructure = TestInfrastructureLayer()
        let dbPath = Foundation.FileManager.default
            .temporaryDirectory
            .appending(component: UUID().uuidString)
            .path()
        let connection = try Connection(dbPath)
        var invalidatorCalled = false
        let holder = await SqliteConnectionHolder(
            logger: infrastructure.logger,
            database: connection,
            invalidator: { invalidatorCalled = true }
        )
        
        // when
        await holder.close()
        
        // then
        #expect(
            await Task { @StorageActor in
                holder.database == nil
            }.value
        )
        #expect(!invalidatorCalled) // Invalidator should not be called on close
    }
    
    @Test
    func testInvalidateCallsInvalidator() async throws {
        // given
        let infrastructure = TestInfrastructureLayer()
        let dbPath = Foundation.FileManager.default
            .temporaryDirectory
            .appending(component: UUID().uuidString)
            .path()
        let connection = try Connection(dbPath)
        var invalidatorCalled = false
        let holder = await SqliteConnectionHolder(
            logger: infrastructure.logger,
            database: connection,
            invalidator: { invalidatorCalled = true }
        )
        
        // when
        await holder.invalidate()
        
        // then
        
        #expect(
            await Task { @StorageActor in
                holder.database == nil
            }.value
        )
        #expect(invalidatorCalled)
    }
    
    @Test
    func testInitializationSetsDatabase() async throws {
        // given
        let infrastructure = TestInfrastructureLayer()
        let dbPath = Foundation.FileManager.default
            .temporaryDirectory
            .appending(component: UUID().uuidString)
            .path()
        let connection = try Connection(dbPath)
        
        // when
        let holder = await SqliteConnectionHolder(
            logger: infrastructure.logger,
            database: connection,
            invalidator: { }
        )
        
        // then
        #expect(
            await Task { @StorageActor in
                holder.database != nil
            }.value
        )
    }
}
