import Testing
import Api
import Domain
import DataTransferObjects
import Foundation
import DefaultUsersRepositoryImplementation
@testable import MockApiImplementation
@testable import Base

private actor ApiProvider {
    let api: MockApi
    var searchCalledCount = 0
    var getCalledCount = 0
    private let getResponse: [UserDto]
    private let searchResponse: [UserDto]

    init(getResponse: [UserDto] = [], searchResponse: [UserDto] = []) async {
        self.getResponse = getResponse
        self.searchResponse = searchResponse
        api = MockApi()
        await api.mutate { api in
            api._runMethodWithParams = { method in
                await self.mutate { s in
                    if let _ = method as? Users.Get {
                        s.getCalledCount += 1
                    } else if let _ = method as? Users.Search {
                        s.searchCalledCount += 1
                    }
                }
                if let _ = method as? Users.Get {
                    return getResponse
                } else if let _ = method as? Users.Search {
                    return searchResponse
                } else {
                    fatalError()
                }
            }
        }
    }
}

private actor MockOfflineMutableRepository: UsersOfflineMutableRepository {
    typealias Update = [User]
    var updates: [Update] = []

    func update(users: [User]) async {
        updates.append(users)
    }
}

@Suite struct UsersRepositoryTests {

    @Test func testGetUsers() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let user = UserDto(
            login: UUID().uuidString,
            friendStatus: .me,
            displayName: "some name",
            avatar: UserDto.Avatar(
                id: nil
            )
        )
        let provider = await ApiProvider(
            getResponse: [user]
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultUsersRepository(
            api: provider.api,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )

        // when

        let response = try await repository.getUsers(ids: [user.id])
        try await taskFactory.runUntilIdle()

        // then

        #expect(await provider.getCalledCount == 1)
        #expect(await offlineRepository.updates == [response])
        #expect(response == [user].map(User.init))
    }

    @Test func testSearchUsers() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let user = UserDto(
            login: UUID().uuidString,
            friendStatus: .me,
            displayName: "some name",
            avatar: UserDto.Avatar(
                id: nil
            )
        )
        let provider = await ApiProvider(
            searchResponse: [user]
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultUsersRepository(
            api: provider.api,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )

        // when

        let response = try await repository.searchUsers(query: "query")
        try await taskFactory.runUntilIdle()

        // then

        #expect(await provider.searchCalledCount == 1)
        #expect(await offlineRepository.updates == [response])
        #expect(response == [user].map(User.init))
    }

    @Test func testGetUsersEmpty() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let provider = await ApiProvider()
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultUsersRepository(
            api: provider.api,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )

        // when

        let response = try await repository.getUsers(ids: [])
        try await taskFactory.runUntilIdle()

        // then

        #expect(await provider.getCalledCount == 0)
        #expect(await offlineRepository.updates == [])
        #expect(response == [])
    }

    @Test func testSearchUsersEmpty() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let provider = await ApiProvider()
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultUsersRepository(
            api: provider.api,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )

        // when

        let response = try await repository.searchUsers(query: "")
        try await taskFactory.runUntilIdle()

        // then

        #expect(await provider.searchCalledCount == 0)
        #expect(await offlineRepository.updates == [])
        #expect(response == [])
    }
}
