public typealias BlockAsyncSubscription<T> = AsyncSubscription<BlockEventSource<T>>

public struct BlockEventSource<Element: Sendable>: AsyncEventSource {
    let block: @Sendable (Element) -> Void

    public func yield(_ element: Element) async {
        block(element)
    }

    public func cancel() async { /* empty */ }
}
