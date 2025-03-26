import PersistentStorage
import Api

public final class MockUserStorage: @unchecked Sendable, UserStorage {
    public var userId: HostId
    public var deviceId: DeviceId
    public var refreshToken: String
    public var operations: [Operation]
    public var onOperationsUpdatedPublisher = EventPublisher<Void>()
    
    public init(
        userId: HostId,
        deviceId: DeviceId,
        refreshToken: String,
        operations: [Operation] = []
    ) {
        self.userId = userId
        self.deviceId = deviceId
        self.refreshToken = refreshToken
        self.operations = operations
    }

    public var onOperationsUpdated: any EventSource<Void> { 
        onOperationsUpdatedPublisher 
    }
    
    public func update(operations: [Operation]) async throws {
        self.operations = operations
    }
    
    public func update(refreshToken: String) async throws {
        self.refreshToken = refreshToken
    }
    
    public func close() async {}
    public func invalidate() async {}
}

public final class MockSandboxStorage: @unchecked Sendable, SandboxStorage {
    public var operations: [Components.Schemas.SomeOperation]
    
    public init(operations: [Components.Schemas.SomeOperation] = []) {
        self.operations = operations
    }
    
    public func update(operations: [Components.Schemas.SomeOperation]) async throws {
        self.operations = operations
    }
    
    public func close() async {}
    public func invalidate() async {}
}

public final class MockUserStoragePreview: UserStoragePreview {
    public let hostId: HostId
    private let storage: UserStorage
    
    public init(hostId: HostId, storage: UserStorage) {
        self.hostId = hostId
        self.storage = storage
    }
    
    public func awake() async throws -> UserStorage {
        storage
    }
}

public final class MockStorageFactory: @unchecked Sendable, StorageFactory {
    public let sandbox: SandboxStorage
    private let availableHosts: [UserStoragePreview]
    private let storageCreator: (HostId, String, [Operation]) async throws -> UserStorage
    
    public init(
        sandbox: SandboxStorage = MockSandboxStorage(),
        availableHosts: [UserStoragePreview] = [],
        storageCreator: @escaping (HostId, String, [Operation]) async throws -> UserStorage = { hostId, refreshToken, operations in
            MockUserStorage(userId: hostId, deviceId: "mock-device", refreshToken: refreshToken, operations: operations)
        }
    ) {
        self.sandbox = sandbox
        self.availableHosts = availableHosts
        self.storageCreator = storageCreator
    }
    
    public var hostsAvailable: [UserStoragePreview] {
        get async throws {
            availableHosts
        }
    }
    
    public func create(
        host: HostId,
        refreshToken: String,
        operations: [Operation]
    ) async throws -> UserStorage {
        try await storageCreator(host, refreshToken, operations)
    }
}

