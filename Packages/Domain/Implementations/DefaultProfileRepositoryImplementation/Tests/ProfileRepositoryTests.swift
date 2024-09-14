import Testing
import PersistentStorage
import DataTransferObjects
import Foundation
import Domain
import Api
import Combine
import ApiDomainConvenience
@testable import Base
@testable import DefaultProfileRepositoryImplementation
@testable import MockApiImplementation

private actor ApiProvider {
    let api: MockApi
    var getCallsCount = 0
    private let getResponse: ProfileDto

    init(getResponse: ProfileDto) async {
        self.getResponse = getResponse
        api = MockApi()
        await api.mutate { api in
            api._runMethodWithoutParams = { method in
                await self.mutate { s in
                    if let _ = method as? Api.Profile.GetInfo {
                        s.getCallsCount += 1
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
                status: .no,
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
            profile: ExternallyUpdatable(),
            taskFactory: taskFactory
        )

        // when

        var subscriptions = Set<AnyCancellable>()
        try await confirmation { confirmation in
            await repository
                .profileUpdated()
                .sink { profileFromPublisher in
                    #expect(profile == profileFromPublisher)
                    confirmation()
                }
                .store(in: &subscriptions)
            let profileFromRepository = try await repository.refreshProfile()
            #expect(profileFromRepository == profile)
            try await taskFactory.runUntilIdle()
        }

        // then

        #expect(await provider.getCallsCount == 1)
        #expect(await offlineRepository.updates == [profile])
    }
}
