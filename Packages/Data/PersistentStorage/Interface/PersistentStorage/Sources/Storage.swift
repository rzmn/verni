public protocol Storage: Sendable {
    func close() async
    func invalidate() async
}
