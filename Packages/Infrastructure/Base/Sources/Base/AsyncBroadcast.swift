import Foundation

public actor AsyncBroadcast<T: Sendable> {
    public actor BlockSubscription: Sendable {
        let block: @Sendable (T) -> Void
        let cancellation: @Sendable () -> Void
        private var canceled = false

        public func cancel() {
            guard !canceled else {
                return
            }
            canceled = true
            cancellation()
        }

        deinit {
            if !canceled {
                cancellation()
            }
        }

        init(block: @escaping @Sendable (T) -> Void, cancellation: @escaping @Sendable () -> Void) {
            self.block = block
            self.cancellation = cancellation
        }
    }

    public actor Subscription {
        public let stream: AsyncStream<T>
        let continuation: AsyncStream<T>.Continuation
        let cancellation: @Sendable () -> Void
        private var canceled = false

        public func cancel() {
            guard !canceled else {
                return
            }
            canceled = true
            cancellation()
        }

        deinit {
            if !canceled {
                cancellation()
            }
        }

        init(stream: AsyncStream<T>, continuation: AsyncStream<T>.Continuation, cancellation: @escaping @Sendable () -> Void) {
            self.stream = stream
            self.continuation = continuation
            self.cancellation = cancellation
        }
    }
    typealias WeakSubscription = @Sendable () -> Subscription?
    private var subscriptions = [String: WeakSubscription]()
    typealias WeakBlockSubscription = @Sendable () -> BlockSubscription?
    private var blockSubscriptions = [String: WeakBlockSubscription]()
    private let taskFactory: TaskFactory

    init(taskFactory: TaskFactory) {
        self.taskFactory = taskFactory
    }

    public func subscription() -> Subscription {
        let id = UUID().uuidString
        let stream: AsyncStream<T>
        let continuation: AsyncStream<T>.Continuation
        (stream, continuation) = AsyncStream.makeStream()
        let subscription = Subscription(stream: stream, continuation: continuation) { [weak self, taskFactory] in
            taskFactory.task { [weak self] in
                await self?.removeSubscription(id: id)
            }
        }
        subscriptions[id] = { [weak subscription] in
            subscription
        }
        return subscription
    }

    public func subscribe(block: @escaping @Sendable (T) -> Void) -> BlockSubscription {
        let id = UUID().uuidString
        let subscription = BlockSubscription(block: block) { [weak self, taskFactory] in
            taskFactory.task { [weak self] in
                await self?.removeSubscription(id: id)
            }
        }
        blockSubscriptions[id] = { [weak subscription] in
            subscription
        }
        return subscription
    }

    func yield(_ value: T) {
        for weakSubscription in subscriptions.values {
            guard let subscription = weakSubscription() else {
                continue
            }
            subscription.continuation.yield(value)
        }
        for weakBlockSubscription in blockSubscriptions.values {
            guard let subscription = weakBlockSubscription() else {
                continue
            }
            subscription.block(value)
        }
    }

    private func removeSubscription(id: String) async {
        if let subscription = subscriptions[id]?() {
            subscription.continuation.finish()
        } else if let subscription = blockSubscriptions[id]?() {
            await subscription.cancel()
        }
        subscriptions[id] = nil
    }
}
