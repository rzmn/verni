import Testing
import OnDemandPolling
import Api
import AsyncExtensions
import TestInfrastructure

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

        let infrastructure = TestInfrastructureLayer()
        let broadcast = AsyncSubject<LongPollFriendsQuery.Update>(
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger.with(prefix: "[events.pub]")
        )
        let update = LongPollFriendsQuery.Update(category: .friends)
        let longPoll = MockLongPoll(friendsBroadcast: broadcast)
        let onDemandSubscription = await OnDemandLongPollSubscription(
            subscribersCount: await broadcast.subscribersCount,
            longPoll: longPoll,
            taskFactory: infrastructure.taskFactory,
            query: LongPollFriendsQuery(),
            logger: infrastructure.logger.with(prefix: "[lp] ")
        )

        // when

        await onDemandSubscription.start { _ in
            Issue.record("should not get updates there")
        }
        await broadcast.yield(update)
        try await infrastructure.testTaskFactory.runUntilIdle()

        // then
    }

    @Test func testHasSubscriptions() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let broadcast = AsyncSubject<LongPollFriendsQuery.Update>(
            taskFactory: infrastructure.taskFactory,
            logger: infrastructure.logger.with(prefix: "[events.pub]")
        )
        let query = LongPollFriendsQuery()
        let update = LongPollFriendsQuery.Update(category: .friends)
        let longPoll = MockLongPoll(friendsBroadcast: broadcast)
        let onDemandSubscription = await OnDemandLongPollSubscription(
            subscribersCount: await broadcast.subscribersCount,
            longPoll: longPoll,
            taskFactory: infrastructure.taskFactory,
            query: LongPollFriendsQuery(),
            logger: infrastructure.logger.with(prefix: "[lp] ")
        )

        // when

        try await confirmation { confirmation in
            await onDemandSubscription.start { _ in
                confirmation()
            }
            await broadcast.yield(update)
            let publisher = await longPoll.poll(for: query)
            let subscription = await publisher.subscribe { _ in
                // ignore
            }
            try await infrastructure.testTaskFactory.runUntilIdle()
            await broadcast.yield(update)
            await subscription.cancel()
            try await infrastructure.testTaskFactory.runUntilIdle()
            await broadcast.yield(update)
        }

        // then
    }
}
