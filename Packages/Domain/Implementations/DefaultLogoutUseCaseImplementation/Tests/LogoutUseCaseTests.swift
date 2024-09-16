import Testing
import Domain
import DataTransferObjects
import Base
@testable import AsyncExtensions
@testable import MockPersistentStorage
@testable import DefaultLogoutUseCaseImplementation

private actor PersistencyProvider {
    let persistency: PersistencyMock
    var invalidateCalledCount = 0

    init() async {
        persistency = PersistencyMock()
        await persistency.mutate { persistency in
            persistency._invalidate = {
                await self.mutate { s in
                    s.invalidateCalledCount += 1
                }
            }
        }
    }
}

@Suite(.timeLimit(.minutes(1))) struct LogoutUseCaseTests {

    @Test func testLogoutFromPublisher() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let subject = AsyncBroadcast<LogoutReason>(taskFactory: taskFactory)
        let provider = await PersistencyProvider()
        let useCase = await DefaultLogoutUseCase(
            persistency: provider.persistency,
            shouldLogout: subject,
            taskFactory: taskFactory
        )
        let reason = LogoutReason.refreshTokenFailed

        // when

        try await confirmation { confirmation in
            let cancellableStream = await useCase.didLogoutPublisher
            let subscription = await cancellableStream.subscribe { reasonFromPublisher in
                #expect(reason == reasonFromPublisher)
                confirmation()
            }
            await subject.yield(reason)
            try await taskFactory.runUntilIdle()
            await subscription.cancel()
        }

        // then

        #expect(await provider.invalidateCalledCount == 1)
    }

    @Test func testLogoutOnlyOnce() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let subject = AsyncBroadcast<LogoutReason>(taskFactory: taskFactory)
        let provider = await PersistencyProvider()
        let useCase = await DefaultLogoutUseCase(
            persistency: provider.persistency,
            shouldLogout: subject,
            taskFactory: taskFactory
        )

        // when

        await useCase.logout()
        await useCase.logout()

        // then

        try await taskFactory.runUntilIdle()
        #expect(await provider.invalidateCalledCount == 1)
    }
}
