import PersistentStorage
import Api
import Logging
internal import SQLite

@StorageActor final class SandboxStorageHolder: Sendable {
    let logger: Logger
    nonisolated lazy var storage: SandboxStorage = MustInit {
        try! await self.doProvideSandbox()
    }
    private let environment: Environment
    
    nonisolated init(logger: Logger, environment: Environment) {
        self.logger = logger
        self.environment = environment
    }
    
    @StorageActor private func doProvideSandbox() async throws -> SandboxStorage {
        logI { "providing sandbox storage..." }
        let sandboxDirectory = environment.containerDirectory.appending(component: HostId.sandbox)
        try environment.fileManager.createDirectory(at: sandboxDirectory)
        let sandboxPath = sandboxDirectory.appending(component: "db.sqlite")
        let exists = try environment.fileManager
            .listDirectory(at: sandboxDirectory, mask: .file)
            .contains(sandboxPath)
        let connection = try Connection(sandboxPath.path())
        let invalidator: @StorageActor @Sendable () -> Void = { [environment] in
            try? environment.fileManager.removeItem(at: sandboxPath)
        }
        if !exists {
            logI { "sandbox storage is not exists yet, preparing..." }
            do {
                try connection.createTablesForSandbox()
            } catch {
                logI { "failed to prepare sandbox storage due error: \(error)" }
                invalidator()
                throw error
            }
        }
        return try SQLiteSandboxStorage(
            logger: logger,
            database: connection,
            invalidator: invalidator
        )
    }
}

extension SandboxStorageHolder: Loggable {}

extension SandboxStorageHolder {
    @StorageActor final class MustInit: SandboxStorage {
        private var _impl: SandboxStorage?
        private var impl: SandboxStorage {
            get async {
                let value: SandboxStorage
                if let existed = _impl {
                    value = existed
                } else {
                    value = try! await implInit()
                }
                return value
            }
        }
        private let implInit: @Sendable () async throws -> SandboxStorage
        
        nonisolated init(implInit: @escaping @Sendable () async throws -> SandboxStorage) {
            self.implInit = implInit
        }
        
        var operations: [Components.Schemas.Operation] {
            get async {
                await impl.operations
            }
        }
        
        func update(operations: [Components.Schemas.Operation]) async throws {
            try await impl.update(operations: operations)
        }
        
        func close() async {
            await impl.close()
        }
        
        func invalidate() async {
            await impl.invalidate()
        }
    }
}
