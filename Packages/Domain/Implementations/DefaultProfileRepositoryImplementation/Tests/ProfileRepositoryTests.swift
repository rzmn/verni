import Testing
import PersistentStorage
import DataTransferObjects
import Foundation
import Base
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

@Suite struct ProfileRepositoryTests {

    @Test func testRefreshProfile() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let profile = Profile(
            user: User(
                id: UUID().uuidString,
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
            taskFactory: taskFactory
        )

        var profileUpdatedIterator = await repository
            .profileUpdated()
            .values
            .makeAsyncIterator()
        async let profileFromPublisher = profileUpdatedIterator.next()

        // when

        let profileFromRepository = try await repository.refreshProfile()

        // then

        let timeout = Task {
            try await Task.sleep(timeInterval: 5)
            if !Task.isCancelled {
                Issue.record("\(#function): timeout failed")
            }
        }
        try await taskFactory.runUntilIdle()

        #expect(await provider.getCallsCount == 1)
        #expect(await offlineRepository.updates == [profile])
        #expect(profileFromRepository == profile)
        #expect(await profileFromPublisher == profile)

        timeout.cancel()
    }
}
