import PersistentStorage

actor InMemoryCache: Sendable {
    private(set) var operations: [Operation]
    private(set) var refreshToken: String
    private(set) var deviceId: String

    init(refreshToken: String, deviceId: String, operations: [Operation]) {
        self.refreshToken = refreshToken
        self.operations = operations
        self.deviceId = deviceId
    }

    func update(operations: [Operation]) async {
        self.operations = operations
    }

    func update(refreshToken: String) async {
        self.refreshToken = refreshToken
    }
}
