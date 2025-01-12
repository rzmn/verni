protocol AsyncEventSource: Sendable, CancellableEventSource {
    associatedtype Element: Sendable
    func yield(_ element: Element) async
}

public protocol CancellableEventSource: Sendable {
    func cancel() async
}
