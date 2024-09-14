import Testing
import Combine
import Domain
import DataTransferObjects
@testable import Base
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
        var logoutSubjectIterator = await useCase
            .didLogoutPublisher
            .values
            .makeAsyncIterator()
        async let logoutFromPublisher = logoutSubjectIterator.next()

        // when

        subject.send(.refreshTokenFailed)
        try await taskFactory.runUntilIdle()

        // then

        #expect(await logoutFromPublisher == .refreshTokenFailed)
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
