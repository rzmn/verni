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
    var updateUsersCalls: [UserDto] = []
    var profile: ProfileDto?

    init() async {
        persistency = PersistencyMock()
        await persistency.performIsolated { persistency in
            persistency.getBlock = { anyDescriptor in
                guard anyDescriptor as? Index<AnyDescriptor<Unkeyed, ProfileDto>> != nil else {
                    fatalError()
                }
                await self.performIsolated { `self` in
                    self.getProfileCalledCount += 1
                }
                return await self.profile
            }
            persistency.updateBlock = { anyDescriptor, anyObject in
                if anyDescriptor as? Index<AnyDescriptor<Unkeyed, ProfileDto>> != nil, let profile = anyObject as? ProfileDto {
                    self.updateProfileCalls.append(profile)
                    self.profile = profile
                } else if anyDescriptor as? Index<AnyDescriptor<UserDto.Identifier, UserDto>> != nil, let user = anyObject as? UserDto {
                    self.updateUsersCalls.append(user)
                } else {
                    fatalError()
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
                status: .notAFriend,
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
        #expect(await provider.updateUsersCalls == [UserDto(domain: profile.user)])
    }
}
