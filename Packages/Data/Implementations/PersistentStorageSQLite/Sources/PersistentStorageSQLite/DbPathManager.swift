import Foundation

@StorageActor protocol DbPathManager<Item>: Sendable {
    associatedtype Item: Sendable
    
    func create(id: String) throws -> Item
    func invalidate(id: String)
    
    var items: [Item] { get throws }
}
