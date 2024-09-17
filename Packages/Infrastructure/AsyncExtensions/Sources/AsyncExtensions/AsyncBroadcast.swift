import Foundation
import Logging

public protocol AsyncPublisher<Element>: Sendable, Identifiable<String> {
    associatedtype Element: Sendable
    func subscribeWithStream() async -> StreamAsyncSubscription<Element>
    func subscribe(with block: @escaping @Sendable (Element) -> Void) async ->  BlockAsyncSubscription<Element>
}

public struct SubscribersCount<T: Sendable>: Sendable {
    public let countPublisher: any AsyncPublisher<Int>
    public let ownerPublisher: any AsyncPublisher<T>
}

public actor AsyncBroadcast<Element: Sendable> {
    public let logger: Logger
    public let id = UUID().uuidString

    private typealias WeakSubscription = @Sendable () -> AnyCancellableSubscription<Element>?
    private var subscriptions = [String: WeakSubscription]()
    private let taskFactory: TaskFactory

    private var subscribersCountTracking: AsyncBroadcast<Int>?
    public lazy var subscribersCount: SubscribersCount<Element> = {
        let countPublisher: any AsyncPublisher<Int>
        if let subscribersCountTracking {
            countPublisher = subscribersCountTracking
        } else {
            let tracking = AsyncBroadcast<Int>(taskFactory: taskFactory, logger: logger.with(prefix: "[sub] "))
            subscribersCountTracking = tracking
            countPublisher = tracking
        }
        return SubscribersCount(
            countPublisher: countPublisher,
            ownerPublisher: self
        )
    }()

    public init(taskFactory: TaskFactory, logger: Logger = .shared) {
        self.logger = logger
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
        subscriptions = subscriptions.filter { (key, value) in
            guard let _ = value() else {
                logI { "subscription outdated with id: \(key)" }
                return false
            }
            return true
        }
        await subscribersCountTracking?.yield(subscriptions.count)
    }
}

extension AsyncBroadcast: Loggable {}
