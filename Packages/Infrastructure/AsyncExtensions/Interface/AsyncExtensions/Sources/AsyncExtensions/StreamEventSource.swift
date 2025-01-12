public typealias StreamAsyncSubscription<T> = AsyncSubscription<StreamEventSource<T>>

public struct StreamEventSource<Element: Sendable>: AsyncEventSource {
    public let stream: AsyncStream<Element>
    let continuation: AsyncStream<Element>.Continuation

    public func yield(_ element: Element) async {
        continuation.yield(element)
    }

    public func cancel() async {
        continuation.finish()
    }
}
