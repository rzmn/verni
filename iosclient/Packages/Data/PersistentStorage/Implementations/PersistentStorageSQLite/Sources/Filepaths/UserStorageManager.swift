import Foundation
import PersistentStorage

@StorageActor protocol UserStorageManager: Sendable {
    func create(hostId: HostId, deviceId: String, refreshToken: String, operations: [Operation]) async throws -> UserStorage
    func invalidator(for hostId: HostId) -> @StorageActor @Sendable () -> Void

    var items: [UserStoragePreview] { get throws }
}
