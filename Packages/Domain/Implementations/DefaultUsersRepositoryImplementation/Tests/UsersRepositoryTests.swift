import Testing
import Api
import Domain
import DataTransferObjects
import Foundation
import DefaultUsersRepositoryImplementation
import Base
@testable import AsyncExtensions
@testable import MockApiImplementation

private actor ApiProvider {
    let api: MockApi
    var searchCalls: [String] = []
    var getCalls: [[UserDto.Identifier]] = []
    private let getResponse: [UserDto]
    private let searchResponse: [UserDto]

    init(getResponse: [UserDto] = [], searchResponse: [UserDto] = []) async {
        self.getResponse = getResponse
        self.searchResponse = searchResponse
        api = MockApi()
        await api.performIsolated { api in
            api.runMethodWithParamsBlock = { method in
                await self.performIsolated { `self` in
                    if let method = method as? Users.Get {
                        self.getCalls.append(method.parameters.ids)
                    } else if let method = method as? Users.Search {
                        self.searchCalls.append(method.parameters.query)
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
    var updates: [ [User] ] = []

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
            friendStatus: .currentUser,
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

        #expect(await provider.getCalls == [[user.id]])
        #expect(await offlineRepository.updates == [response])
        #expect(response == [user].map(User.init))
    }

    @Test func testSearchUsers() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let user = UserDto(
            login: UUID().uuidString,
            friendStatus: .currentUser,
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
        let searchQuery = "query"

        // when

        let response = try await repository.searchUsers(query: searchQuery)
        try await taskFactory.runUntilIdle()

        // then

        #expect(await provider.searchCalls == [searchQuery])
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

        #expect(await provider.getCalls == [])
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

        #expect(await provider.searchCalls == [])
        #expect(await offlineRepository.updates == [])
        #expect(response == [])
    }
}
