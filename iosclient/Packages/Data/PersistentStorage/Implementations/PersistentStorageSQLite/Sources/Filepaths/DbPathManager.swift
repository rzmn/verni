import Foundation
import PersistentStorage

@StorageActor protocol DbPathManager: Sendable {
    func create(hostId: HostId, refreshToken: String, operations: [Operation]) async throws -> UserStorage
    func invalidator(for hostId: HostId) -> @StorageActor @Sendable () -> Void

    var items: [UserStoragePreview] { get throws }
}
