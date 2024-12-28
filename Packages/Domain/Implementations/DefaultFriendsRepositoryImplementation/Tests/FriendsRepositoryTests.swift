import Testing
import PersistentStorage
import DataTransferObjects
import Foundation
import Domain
import Api
import ApiDomainConvenience
import Base
import Infrastructure
import TestInfrastructure
import AsyncExtensions
@testable import DefaultFriendsRepositoryImplementation
@testable import MockApiImplementation

private struct MockLongPoll: LongPoll {
    let friendsBroadcast: AsyncSubject<LongPollFriendsQuery.Update>

    func poll<Query: LongPollQuery>(for query: Query) async -> any AsyncBroadcast<Query.Update> {
        if Query.self == LongPollFriendsQuery.self {
            return friendsBroadcast as! any AsyncBroadcast<Query.Update>
        } else {
            fatalError()
        }
    }
}

private actor ApiProvider {
    let api: MockApi
    let mockLongPoll: MockLongPoll
    var getFriendsCalls: [ [Int] ] = []
    var getUsersCalls: [ [UserDto.Identifier] ] = []
    let getFriendsResponse: [Int: [UserDto.Identifier]]
    let getUsersResponse: [UserDto]

    init(
        getFriendsResponse: [Int: [UserDto.Identifier]] = [:],
        getUsersResponse: [UserDto] = [],
        infrastructure: InfrastructureLayer
    ) async {
        self.getFriendsResponse = getFriendsResponse
        self.getUsersResponse = getUsersResponse
        api = MockApi()
        mockLongPoll = MockLongPoll(friendsBroadcast: AsyncSubject(taskFactory: infrastructure.taskFactory, logger: infrastructure.logger))
        await api.performIsolated { api in
            api.runMethodWithParamsBlock = { method in
                return await self.performIsolated { `self` in
                    if let method = method as? Friends.Get {
                        self.getFriendsCalls.append(method.parameters.statuses)
                        return self.getFriendsResponse
                    } else if let method = method as? Users.Get {
                        self.getUsersCalls.append(method.parameters.ids)
                        return self.getUsersResponse
                    } else {
                        fatalError()
                    }
                }
            }
        }
    }
}

private actor MockOfflineMutableRepository: FriendsOfflineMutableRepository {
    var updates: [([FriendshipKind: [User]], FriendshipKindSet)] = []

    func storeFriends(_ friends: [FriendshipKind: [User]], for set: FriendshipKindSet) async {
        updates.append((friends, set))
    }
}

@Suite(.timeLimit(.minutes(1))) struct FriendsRepositoryTests {

    @Test func testRefreshFriends() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let set: FriendshipKindSet = [.friends, .subscription]
        let friends: [Int: [User]] = [
            FriendshipKindDto.friends.rawValue: [],
            FriendshipKindDto.subscription.rawValue: [
                User(
                    id: UUID().uuidString,
                    status: .outgoing,
                    displayName: "some name",
                    avatar: nil
                )
            ]
        ]
        let provider = await ApiProvider(
            getFriendsResponse: friends.mapValues { $0.map(\.id) },
            getUsersResponse: friends.values.flatMap { $0.map(UserDto.init) },
            infrastructure: infrastructure
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultFriendsRepository(
            api: provider.api,
            longPoll: provider.mockLongPoll,
            logger: infrastructure.logger,
            offline: offlineRepository,
            taskFactory: infrastructure.taskFactory
        )
        let friendsCasted: [FriendshipKind: [User]] = friends.reduce(into: [:]) { dict, kv in
            guard let key = FriendshipKindDto(rawValue: kv.key) else {
                return
            }
            dict[FriendshipKind(dto: key)] = kv.value
        }

        // when

        try await confirmation { confirmation in
            let cancellableStream = await repository.friendsUpdated(ofKind: set).subscribeWithStream()
            let stream = await cancellableStream.eventSource.stream
            let friendsFromRepository = try await repository.refreshFriends(ofKind: set)
            infrastructure.taskFactory.task {
                for await friendsFromPublisher in stream {
                    #expect(friendsCasted == friendsFromPublisher)
                    confirmation()
                }
            }
            #expect(friendsFromRepository == friendsCasted)
            await cancellableStream.cancel()
            try await infrastructure.testTaskFactory.runUntilIdle()
        }

        // then

        #expect(await provider.getUsersCalls.map { Set($0) } == [Set(friends.values.flatMap { $0 }.map(\.id))])
        #expect(await provider.getFriendsCalls == [ set.array.map(FriendshipKindDto.init).map(\.rawValue) ])
        #expect(await offlineRepository.updates.map(\.0) == [friendsCasted])
        #expect(await offlineRepository.updates.map(\.1) == [set])
    }

    @Test func testFriendsPolling() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let set: FriendshipKindSet = [.friends, .subscription]
        let friends: [Int: [User]] = [
            FriendshipKindDto.friends.rawValue: [],
            FriendshipKindDto.subscription.rawValue: [
                User(
                    id: UUID().uuidString,
                    status: .outgoing,
                    displayName: "some name",
                    avatar: nil
                )
            ]
        ]
        let provider = await ApiProvider(
            getFriendsResponse: friends.mapValues { $0.map(\.id) },
            getUsersResponse: friends.values.flatMap { $0.map(UserDto.init) },
            infrastructure: infrastructure
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultFriendsRepository(
            api: provider.api,
            longPoll: provider.mockLongPoll,
            logger: infrastructure.logger,
            offline: offlineRepository,
            taskFactory: infrastructure.taskFactory
        )
        let friendsCasted: [FriendshipKind: [User]] = friends.reduce(into: [:]) { dict, kv in
            guard let key = FriendshipKindDto(rawValue: kv.key) else {
                return
            }
            dict[FriendshipKind(dto: key)] = kv.value
        }

        // when

        try await confirmation { confirmation in
            let subscription = await repository.friendsUpdated(ofKind: set).subscribe { friendsFromPublisher in
                #expect(friendsCasted == friendsFromPublisher)
                confirmation()
            }
            try await infrastructure.testTaskFactory.runUntilIdle()
            await provider.mockLongPoll.friendsBroadcast.yield(
                LongPollFriendsQuery.Update(category: .friends)
            )
            try await infrastructure.testTaskFactory.runUntilIdle()
            await subscription.cancel()
        }

        // then

        #expect(await provider.getUsersCalls.map { Set($0) } == [Set(friends.values.flatMap { $0 }.map(\.id))])
        #expect(await provider.getFriendsCalls == [ set.array.map(FriendshipKindDto.init).map(\.rawValue) ])
        #expect(await offlineRepository.updates.map(\.0) == [friendsCasted])
        #expect(await offlineRepository.updates.map(\.1) == [set])
    }
}
