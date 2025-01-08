import Foundation
import PersistentStorage

extension HostId {
    static var localStorage: HostId {
        "local"
    }
}

@StorageActor protocol DbPathManager<Item>: Sendable {
    associatedtype Item: Sendable

    func create(id: HostId) throws -> Item
    func invalidate(id: HostId)

    var items: [Item] { get throws }
}
