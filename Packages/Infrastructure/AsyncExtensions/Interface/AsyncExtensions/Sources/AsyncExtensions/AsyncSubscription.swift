public actor AsyncSubscription<EventSource>: Sendable {
    public let eventSource: EventSource
    let cancellation: @Sendable () -> Void
    private var canceled = false

    deinit {
        if !canceled {
            cancellation()
        }
    }

    init(eventSource: EventSource, cancellation: @escaping @Sendable () -> Void) {
        self.eventSource = eventSource
        self.cancellation = cancellation
    }
}

extension AsyncSubscription: AsyncEventSource where EventSource: AsyncEventSource {
    typealias Element = EventSource.Element
    func yield(_ element: Element) async {
        await eventSource.yield(element)
    }
}

extension AsyncSubscription: CancellableEventSource {
    public func cancel() async {
        guard !canceled else {
            return
        }
        if let cancellable = eventSource as? CancellableEventSource {
            await cancellable.cancel()
        }
        canceled = true
        cancellation()
    }
}
