import Api

public typealias HostId = String
public typealias DeviceId = String

public protocol Persistency: Sendable {
    var userId: HostId { get async }
    var deviceId: DeviceId { get async }

    var refreshToken: String { get async throws }
    var operations: [Operation] { get async throws }
    
    func update(operations: [Operation]) async throws
    func update(refreshToken: String) async throws

    func close() async
    func invalidate() async
}
