import Testing
import Domain
import DataTransferObjects
import Base
import DataLayerDependencies
import Api
import PersistentStorage
@testable import AsyncExtensions
@testable import MockPersistentStorage
@testable import DefaultLogoutUseCaseImplementation
@testable import MockApiImplementation

private actor PersistencyProvider {
    let persistency: PersistencyMock
    var invalidateCalledCount = 0

    init() async {
        persistency = PersistencyMock()
        await persistency.performIsolated { persistency in
            persistency.invalidateBlock = {
                await self.performIsolated { `self` in
                    self.invalidateCalledCount += 1
                }
            }
        }
    }
}

private struct MockLongPoll: LongPoll {
    func poll<Query: LongPollQuery>(for query: Query) async -> any AsyncBroadcast<Query.Update> {
        fatalError()
    }
}

private final class MockDataLayerSession: AuthenticatedDataLayerSession {
    var api: any Api.ApiProtocol {
        MockApi()
    }
    
    var longPoll: any Api.LongPoll {
        MockLongPoll()
    }
    
    let persistency: any PersistentStorage.Persistency
    
    var authenticationLostHandler: any AsyncExtensions.AsyncBroadcast<Void> {
        fatalError()
    }
    
    init(persistency: any PersistentStorage.Persistency = PersistencyMock()) {
        self.persistency = persistency
    }
    
    func logout() async {
        await persistency.invalidate()
    }
}

@Suite(.timeLimit(.minutes(1))) struct LogoutUseCaseTests {

    @Test func testLogoutFromPublisher() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let subject = AsyncSubject<LogoutReason>(taskFactory: taskFactory, logger: .shared)
        let provider = await PersistencyProvider()
        let useCase = await DefaultLogoutUseCase(
            session: MockDataLayerSession(persistency: provider.persistency),
            shouldLogout: subject,
            taskFactory: taskFactory,
            logger: .shared
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
        let subject = AsyncSubject<LogoutReason>(taskFactory: taskFactory, logger: .shared)
        let provider = await PersistencyProvider()
        let useCase = await DefaultLogoutUseCase(
            session: MockDataLayerSession(persistency: provider.persistency),
            shouldLogout: subject,
            taskFactory: taskFactory,
            logger: .shared
        )

        // when

        await useCase.logout()
        await useCase.logout()

        // then

        try await taskFactory.runUntilIdle()
        #expect(await provider.invalidateCalledCount == 1)
    }
}
