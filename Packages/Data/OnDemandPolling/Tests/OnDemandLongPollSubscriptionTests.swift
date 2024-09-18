import Testing
import OnDemandPolling
import Api
@testable import AsyncExtensions

private struct MockLongPoll: LongPoll {
    let friendsBroadcast: AsyncSubject<LongPollFriendsQuery.Update>

    func poll<Query: LongPollQuery>(for query: Query) async -> any AsyncBroadcast<Query.Update> {
        if Query.self == LongPollFriendsQuery.self {
            return friendsBroadcast as! any AsyncBroadcast<Query.Update>
        } else {
            fatalError()
        }
    }
}

@Suite struct OnDemandLongPollSubscriptionTests {

    @Test func testNoSubscriptions() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let broadcast = AsyncSubject<LongPollFriendsQuery.Update>(
            taskFactory: taskFactory,
            logger: .shared.with(prefix: "[events.pub]")
        )
        let update = LongPollFriendsQuery.Update(category: .friends)
        let longPoll = MockLongPoll(friendsBroadcast: broadcast)
        let onDemandSubscription = await OnDemandLongPollSubscription(
            subscribersCount: await broadcast.subscribersCount,
            longPoll: longPoll,
            taskFactory: taskFactory,
            query: LongPollFriendsQuery(),
            logger: .shared.with(prefix: "[lp] ")
        )

        // when

        await onDemandSubscription.start { update in
            Issue.record("should not get updates there")
        }
        await broadcast.yield(update)
        try await taskFactory.runUntilIdle()

        // then
    }

    @Test func testHasSubscriptions() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let broadcast = AsyncSubject<LongPollFriendsQuery.Update>(
            taskFactory: taskFactory,
            logger: .shared.with(prefix: "[events.pub]")
        )
        let query = LongPollFriendsQuery()
        let update = LongPollFriendsQuery.Update(category: .friends)
        let longPoll = MockLongPoll(friendsBroadcast: broadcast)
        let onDemandSubscription = await OnDemandLongPollSubscription(
            subscribersCount: await broadcast.subscribersCount,
            longPoll: longPoll,
            taskFactory: taskFactory,
            query: LongPollFriendsQuery(),
            logger: .shared.with(prefix: "[lp] ")
        )

        // when

        try await confirmation { confirmation in
            await onDemandSubscription.start { update in
                confirmation()
            }
            await broadcast.yield(update)
            let publisher = await longPoll.poll(for: query)
            let subscription = await publisher.subscribe { _ in
                // ignore
            }
            try await taskFactory.runUntilIdle()
            await broadcast.yield(update)
            await subscription.cancel()
            try await taskFactory.runUntilIdle()
            await broadcast.yield(update)
        }



        // then
    }
}
