import Testing
import PersistentStorage
import DataTransferObjects
import Foundation
import Domain
import Api
import ApiDomainConvenience
import Base
@testable import AsyncExtensions
@testable import DefaultProfileRepositoryImplementation
@testable import MockApiImplementation

private actor ApiProvider {
    let api: MockApi
    var getCallsCount = 0
    private let getResponse: ProfileDto

    init(getResponse: ProfileDto) async {
        self.getResponse = getResponse
        api = MockApi()
        await api.performIsolated { api in
            api.runMethodWithoutParamsBlock = { method in
                await self.performIsolated { `self` in
                    if let _ = method as? Api.Profile.GetInfo {
                        self.getCallsCount += 1
                    }
                }
                return self.getResponse
            }
        }
    }
}

private actor MockOfflineMutableRepository: ProfileOfflineMutableRepository {
    var updates: [Domain.Profile] = []

    func update(profile: Domain.Profile) async {
        updates.append(profile)
    }
}

@Suite(.timeLimit(.minutes(1))) struct ProfileRepositoryTests {

    @Test func testRefreshProfile() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let profile = Profile(
            user: User(
                id: UUID().uuidString,
                status: .notAFriend,
                displayName: "some name",
                avatar: nil
            ),
            email: "e@e.com",
            isEmailVerified: true
        )
        let provider = await ApiProvider(
            getResponse: ProfileDto(domain: profile)
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = await DefaultProfileRepository(
            api: provider.api,
            logger: .shared,
            offline: offlineRepository,
            profile: ExternallyUpdatable(taskFactory: taskFactory),
            taskFactory: taskFactory
        )

        // when

        try await confirmation { confirmation in
            let cancellableStream = await repository.profileUpdated().subscribeWithStream()
            let stream = await cancellableStream.eventSource.stream
            let profileFromRepository = try await repository.refreshProfile()
            taskFactory.task {
                for await profileFromPublisher in stream {
                    #expect(profile == profileFromPublisher)
                    confirmation()
                }
            }
            #expect(profileFromRepository == profile)
            await cancellableStream.cancel()
            try await taskFactory.runUntilIdle()
        }

        // then

        #expect(await provider.getCallsCount == 1)
        #expect(await offlineRepository.updates == [profile])
    }
}
