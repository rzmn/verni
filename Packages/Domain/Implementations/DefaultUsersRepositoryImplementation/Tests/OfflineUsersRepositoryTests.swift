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
    var getUserCalled = false
    var users = [UserDto.ID: UserDto]()

    init() async {
        persistency = PersistencyMock()
        await persistency.mutate { persistency in
            persistency._userWithID = { id in
                await self.mutate { s in
                    s.getUserCalled = true
                }
                return await self.users[id]
            }
            persistency._updateUsers = { users in
                await self.mutate { s in
                    for user in users {
                        s.users[user.id] = user
                    }
                }
            }
        }
    }
}

@Suite struct OfflineUsersRepositoryTests {

    @Test func testOfflineRepositoryGetNoUsers() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultUsersOfflineRepository(persistency: provider.persistency)
        let uid = UUID().uuidString

        // when

        let user = await repository.getUser(id: uid)

        // then

        #expect(user == nil)
        #expect(await provider.getUserCalled)
    }

    @Test func testOfflineRepositorySetUser() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultUsersOfflineRepository(persistency: provider.persistency)
        let user = User(
            id: UUID().uuidString,
            displayName: "some name",
            avatar: nil
        )

        // when

        await repository.update(users: [user])

        // then

        #expect(await repository.getUser(id: user.id) == user)
        #expect(await provider.getUserCalled)
    }
}
