import Testing
import Combine
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
        let subject = PassthroughSubject<LogoutReason, Never>()
        let provider = await PersistencyProvider()
        let useCase = await DefaultLogoutUseCase(
            persistency: provider.persistency,
            shouldLogout: subject.eraseToAnyPublisher(),
            taskFactory: taskFactory
        )
        let reason = LogoutReason.refreshTokenFailed

        // when

        var subscriptions = Set<AnyCancellable>()
        try await confirmation { confirmation in
            await useCase
                .didLogoutPublisher
                .sink { reasonFromPublisher in
                    #expect(reason == reasonFromPublisher)
                    confirmation()
                }
                .store(in: &subscriptions)
            subject.send(reason)
            try await taskFactory.runUntilIdle()
        }

        // then

        #expect(await provider.invalidateCalledCount == 1)
    }

    @Test func testLogoutOnlyOnce() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let subject = PassthroughSubject<LogoutReason, Never>()
        let provider = await PersistencyProvider()
        let useCase = await DefaultLogoutUseCase(
            persistency: provider.persistency,
            shouldLogout: subject.eraseToAnyPublisher(),
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
