import AsyncExtensions
import Api

public actor OnDemandLongPollSubscription<Q: LongPollQuery> {
    private let taskFactory: TaskFactory
    private let subscribersCountPublisher: any AsyncPublisher<Int>
    private let longPollPublisher: any AsyncPublisher<Q.Update>

    private var subscribersCountSubscription: (any CancellableEventSource)?
    private var longPollSubscription: (any CancellableEventSource)?

    public init(
        subscribersCountPublisher: any AsyncPublisher<Int>,
        longPoll: LongPoll,
        taskFactory: TaskFactory,
        query: Q
    ) async where Q.Update: Decodable {
        self.subscribersCountPublisher = subscribersCountPublisher
        longPollPublisher = await longPoll.poll(for: query)
        self.taskFactory = taskFactory
    }

    public func start(onLongPoll: @escaping @Sendable (Q.Update) -> Void) async {
        subscribersCountSubscription = await subscribersCountPublisher.subscribe { [weak self, taskFactory] subscribersCount in
            taskFactory.task { [weak self] in
                await self?.mutate { s in
                    let hadSubscribers = s.longPollSubscription != nil
                    let hasSubscribers = subscribersCount > 0
                    guard hadSubscribers != hasSubscribers else {
                        return
                    }
                    await s.longPollSubscription?.cancel()
                    if hasSubscribers {
                        s.longPollSubscription = await s.longPollPublisher.subscribe { update in
                            onLongPoll(update)
                        }
                    } else {
                        s.longPollSubscription = nil
                    }
                }
            }
        }
    }
}
