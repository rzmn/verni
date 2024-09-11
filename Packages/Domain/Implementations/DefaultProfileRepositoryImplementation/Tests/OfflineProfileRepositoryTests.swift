import Testing
import PersistentStorage
import DataTransferObjects
import Foundation
import Base
import Domain
import ApiDomainConvenience
@testable import DefaultProfileRepositoryImplementation
@testable import MockPersistentStorage

private actor PersistencyProvider {
    let persistency: PersistencyMock
    var getProfileCalledCount = 0
    var updateProfileCalls: [ProfileDto] = []
    var updateUsersCalls: [ [UserDto] ] = []
    var profile: ProfileDto?

    init() async {
        persistency = PersistencyMock()
        await persistency.mutate { persistency in
            persistency._getProfile = {
                await self.mutate { s in
                    s.getProfileCalledCount += 1
                }
                return await self.profile
            }
            persistency._updateProfile = { profile in
                await self.mutate { s in
                    s.updateProfileCalls.append(profile)
                    s.profile = profile
                }
            }
            persistency._updateUsers = { users in
                await self.mutate { s in
                    s.updateUsersCalls.append(users)
                }
            }
        }
    }
}

@Suite struct OfflineProfileRepositoryTests {

    @Test func testGetNoProfile() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultProfileOfflineRepository(persistency: provider.persistency)

        // when

        let profile = await repository.getProfile()

        // then

        #expect(profile == nil)
        #expect(await provider.getProfileCalledCount == 1)
    }

    @Test func testSetUser() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultProfileOfflineRepository(persistency: provider.persistency)
        let profile = Profile(
            user: User(
                id: UUID().uuidString,
                displayName: "some name",
                avatar: nil
            ),
            email: "e@e.com",
            isEmailVerified: true
        )

        // when

        await repository.update(profile: profile)
        let profileFromRepository = await repository.getProfile()

        // then

        #expect(profileFromRepository == profile)
        #expect(await provider.updateProfileCalls == [profile].map(ProfileDto.init))
        #expect(await provider.getProfileCalledCount == 1)
        #expect(await provider.updateUsersCalls == [[UserDto(domain: profile.user)]])
    }
}
