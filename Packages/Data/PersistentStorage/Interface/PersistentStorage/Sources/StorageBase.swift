public protocol StorageBase: Sendable {
    func close() async
    func invalidate() async
}
