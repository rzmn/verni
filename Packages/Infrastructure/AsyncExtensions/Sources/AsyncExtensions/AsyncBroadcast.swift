import Foundation

public protocol AsyncPublisher<Element>: Sendable {
    associatedtype Element: Sendable
    func subscribeWithStream() async -> StreamAsyncSubscription<Element>
    func subscribe(with block: @escaping @Sendable (Element) -> Void) async ->  BlockAsyncSubscription<Element>
}

public actor AsyncBroadcast<Element: Sendable> {
    private typealias WeakSubscription = @Sendable () -> AnyCancellableSubscription<Element>?
    private var subscriptions = [String: WeakSubscription]()
    private let taskFactory: TaskFactory
    private let subscribersCountTracking: AsyncBroadcast<Int>?

    public init(taskFactory: TaskFactory, subscribersCountTracking: AsyncBroadcast<Int>? = nil) {
        self.taskFactory = taskFactory
        self.subscribersCountTracking = subscribersCountTracking
    }

    public func yield(_ value: Element) async {
        for weakSubscription in subscriptions.values {
            guard let subscription = weakSubscription() else {
                continue
            }
            await subscription.yield(value)
        }
    }
}

extension AsyncBroadcast: AsyncPublisher {
    public func subscribeWithStream() async -> StreamAsyncSubscription<Element> {
        let stream: AsyncStream<Element>
        let continuation: AsyncStream<Element>.Continuation
        (stream, continuation) = AsyncStream.makeStream()
        return await store(
            source: StreamEventSource(
                stream: stream,
                continuation: continuation
            )
        )
    }

    public func subscribe(with block: @escaping @Sendable (Element) -> Void) async ->  BlockAsyncSubscription<Element> {
        await store(source: BlockEventSource(block: block))
    }
}

// MARK: - Private

extension AsyncBroadcast {
    private func store<Source: AsyncEventSource>(
        source: Source
    ) async -> AsyncSubscription<Source> where Source.Element == Element {
        let id = UUID().uuidString
        let subscription = AsyncSubscription(eventSource: source) { [weak self, taskFactory] in
            taskFactory.task { [weak self] in
                await self?.removeSubscription(id: id)
            }
        }
        subscriptions[id] = { [weak subscription] in
            subscription.flatMap(AnyCancellableSubscription.init)
        }
        await subscribersCountTracking?.yield(subscriptions.count)
        return subscription
    }

    private func removeSubscription(id: String) async {
        await subscriptions[id]?()?.cancel()
        subscriptions[id] = nil
        await subscribersCountTracking?.yield(subscriptions.count)
    }
}
