import Foundation
import PersistentStorage

@StorageActor protocol DbPathManager<Item>: Sendable {
    associatedtype Item: Sendable

    func create(id: HostId) throws -> Item
    func invalidate(id: HostId)

    var items: [Item] { get throws }
}
