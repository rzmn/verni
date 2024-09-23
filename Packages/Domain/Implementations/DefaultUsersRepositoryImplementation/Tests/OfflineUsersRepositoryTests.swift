import Testing
import PersistentStorage
import DataTransferObjects
import Foundation
import Base
import Domain
import ApiDomainConvenience
@testable import DefaultUsersRepositoryImplementation
@testable import MockPersistentStorage

private actor PersistencyProvider {
    let persistency: PersistencyMock
    var getUserCalledCount: [UserDto.Identifier: Int] = [:]
    var updateUsersCalls: [ [UserDto] ] = []
    var users = [UserDto.Identifier: UserDto]()

    init() async {
        persistency = PersistencyMock()
        await persistency.performIsolated { persistency in
            persistency.userWithIDBlock = { id in
                await self.performIsolated { `self` in
                    self.getUserCalledCount[id] = self.getUserCalledCount[id, default: 0] + 1
                }
                return await self.users[id]
            }
            persistency.updateUsersBlock = { users in
                await self.performIsolated { `self` in
                    self.updateUsersCalls.append(users)
                    for user in users {
                        self.users[user.id] = user
                    }
                }
            }
        }
    }
}

@Suite struct OfflineUsersRepositoryTests {

    @Test func testGetNoUsers() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultUsersOfflineRepository(persistency: provider.persistency)
        let uid = UUID().uuidString

        // when

        let user = await repository.getUser(id: uid)

        // then

        #expect(user == nil)
        #expect(await provider.getUserCalledCount[uid, default: 0] == 1)
    }

    @Test func testSetUser() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultUsersOfflineRepository(persistency: provider.persistency)
        let user = User(
            id: UUID().uuidString,
            status: .notAFriend,
            displayName: "some name",
            avatar: nil
        )

        // when

        await repository.update(users: [user])
        let userFromRepository = await repository.getUser(id: user.id)

        // then

        #expect(userFromRepository == user)
        #expect(await provider.updateUsersCalls == [[user].map(UserDto.init)])
        #expect(await provider.getUserCalledCount[user.id, default: 0] == 1)
    }
}
