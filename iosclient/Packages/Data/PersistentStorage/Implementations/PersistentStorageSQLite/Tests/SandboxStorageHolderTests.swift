import Testing
import Foundation
import TestInfrastructure
import Convenience
import Filesystem
import PersistentStorage
import Api
@testable import PersistentStorageSQLite
internal import SQLite

@Suite
struct SandboxStorageHolderTests {
    
    @Test
    func testCreatesStorageAndDirectory() async throws {
        // given
        let infrastructure = TestInfrastructureLayer()
        let environment = try Environment(
            logger: infrastructure.logger,
            fileManager: infrastructure.fileManager,
            versionLabel: UUID().uuidString,
            containerDirectory: Foundation.FileManager.default
                .temporaryDirectory
                .appending(component: UUID().uuidString)
        )
        let holder = SandboxStorageHolder(
            logger: infrastructure.logger,
            environment: environment
        )
        
        // when
        let _ = await holder.storage.operations
        
        // then
        let sandboxDir = environment.containerDirectory.appending(component: HostId.sandbox)
        let dbPath = sandboxDir.appending(component: "db.sqlite")
        #expect(try infrastructure.fileManager.listDirectory(at: sandboxDir, mask: .file).contains(dbPath))
    }
}
