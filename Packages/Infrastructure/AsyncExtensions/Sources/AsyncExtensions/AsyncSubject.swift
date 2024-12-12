import Foundation
import Logging

public protocol AsyncBroadcast<Element>: Sendable, Identifiable<String> {
    associatedtype Element: Sendable
    func subscribeWithStream() async -> StreamAsyncSubscription<Element>
    func subscribe(with block: @escaping @Sendable (Element) -> Void) async -> BlockAsyncSubscription<Element>
}

public struct SubscribersCount<T: Sendable>: Sendable {
    public let countPublisher: any AsyncBroadcast<Int>
    public let ownerPublisher: any AsyncBroadcast<T>
}

public actor AsyncSubject<Element: Sendable> {
    public let logger: Logger
    public let id = UUID().uuidString

    private typealias WeakSubscription = @Sendable () -> AnyCancellableSubscription<Element>?
    private var subscriptions = [String: WeakSubscription]()
    private let taskFactory: TaskFactory

    private var subscribersCountTracking: AsyncSubject<Int>?
    public lazy var subscribersCount: SubscribersCount<Element> = {
        let countPublisher: any AsyncBroadcast<Int>
        if let subscribersCountTracking {
            countPublisher = subscribersCountTracking
        } else {
            let tracking = AsyncSubject<Int>(taskFactory: taskFactory, logger: logger, logTag: "🧮")
            subscribersCountTracking = tracking
            countPublisher = tracking
        }
        return SubscribersCount(
            countPublisher: countPublisher,
            ownerPublisher: self
        )
    }()

    public init(taskFactory: TaskFactory, logger: Logger, logTag: String = "🌊") {
        self.logger = logger.with(prefix: logTag)
        self.taskFactory = taskFactory
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

extension AsyncSubject: AsyncBroadcast {
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

    public func subscribe(with block: @escaping @Sendable (Element) -> Void) async -> BlockAsyncSubscription<Element> {
        await store(source: BlockEventSource(block: block))
    }
}

// MARK: - Private

extension AsyncSubject {
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
        logI { "stored subscription \(Source.self)[\(id)]" }
        await refreshSubscriptionsCount()
        return subscription
    }

    private func removeSubscription(id: String) async {
        await subscriptions[id]?()?.cancel()
        subscriptions[id] = nil
        logI { "removed subscription with id: \(id)" }
        await refreshSubscriptionsCount()
    }

    private func refreshSubscriptionsCount() async {
        subscriptions = subscriptions.filter { (_, value) in
            value() != nil
        }
        await subscribersCountTracking?.yield(subscriptions.count)
    }
}

extension AsyncSubject: Loggable {}
