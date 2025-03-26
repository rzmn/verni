import AsyncExtensions

public typealias HostId = String
public typealias DeviceId = String

public protocol UserStorage: Storage {
    var userId: HostId { get async }
    var deviceId: DeviceId { get async }

    var refreshToken: String { get async }
    
    var onOperationsUpdated: any EventSource<Void> { get }
    var operations: [Operation] { get async }
    
    func update(operations: [Operation]) async throws
    func update(refreshToken: String) async throws

    func close() async
    func invalidate() async
}
