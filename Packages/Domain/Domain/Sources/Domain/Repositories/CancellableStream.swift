public protocol CancellableStream<Element>: Sendable where Element: Sendable {
    associatedtype Element
    var stream: AsyncStream<Element> { get async }
    func cancel() async
}
