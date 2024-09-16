struct AnyCancellableSubscription<Element: Sendable>: AsyncEventSource, CancellableEventSource {
    private let cancellable: any CancellableEventSource
    private let yieldHandler: @Sendable (Element) async -> Void

    init<Source: AsyncEventSource & CancellableEventSource>(source: Source) where Source.Element == Element {
        cancellable = source
        yieldHandler = source.yield
    }

    func yield(_ element: Element) async {
        await yieldHandler(element)
    }

    func cancel() async {
        await cancellable.cancel()
    }
}
