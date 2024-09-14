import Testing
import PersistentStorage
import DataTransferObjects
import Foundation
import Domain
import Api
import Combine
import ApiDomainConvenience
@testable import Base
@testable import DefaultFriendsRepositoryImplementation
@testable import MockApiImplementation

private actor ApiProvider {
    let api: MockApi
    let mockLongPoll: MockLongPoll
    var getFriendsCalls: [ [Int] ] = []
    var getUsersCalls: [ [UserDto.ID] ] = []
    let getFriendsResponse: [Int: [UserDto.ID]]
    let getUsersResponse: [UserDto]
    let getFriendsSubject = PassthroughSubject<LongPollFriendsQuery.Update, Never>()

    init(
        getFriendsResponse: [Int: [UserDto.ID]] = [:],
        getUsersResponse: [UserDto] = []
    ) async {
        self.getFriendsResponse = getFriendsResponse
        self.getUsersResponse = getUsersResponse
        api = MockApi()
        mockLongPoll = MockLongPoll()
        await api.mutate { api in
            api._runMethodWithParams = { method in
                return await self.mutate { s in
                    if let method = method as? Friends.Get {
                        s.getFriendsCalls.append(method.parameters.statuses)
                        return s.getFriendsResponse
                    } else if let method = method as? Users.Get {
                        s.getUsersCalls.append(method.parameters.ids)
                        return s.getUsersResponse
                    } else {
                        fatalError()
                    }
                }
            }
        }
        await mockLongPoll.mutate { longPoll in
            longPoll._poll = { query in
                if let _ = query as? LongPollFriendsQuery {
                    return self.getFriendsSubject
                        .map {
                            $0 as Decodable & Sendable
                        }
                        .eraseToAnyPublisher()
                } else {
                    fatalError()
                }
            }
        }
    }
}

private actor MockOfflineMutableRepository: FriendsOfflineMutableRepository {
    var updates: [([FriendshipKind: [User]], FriendshipKindSet)] = []

    func storeFriends(_ friends: [FriendshipKind : [User]], for set: FriendshipKindSet) async {
        updates.append((friends, set))
    }
}

@Suite(.timeLimit(.minutes(1))) struct FriendsRepositoryTests {

    @Test func testRefreshFriends() async throws {

        // given

        let taskFactory = TestTaskFactory()
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
            getUsersResponse: friends.values.flatMap { $0.map(UserDto.init) }
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultFriendsRepository(
            api: provider.api,
            longPoll: provider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )
        let friendsCasted: [FriendshipKind: [User]] = friends.reduce(into: [:]) { dict, kv in
            guard let key = FriendshipKindDto(rawValue: kv.key) else {
                return
            }
            dict[FriendshipKind(dto: key)] = kv.value
        }

        // when

        var subscriptions = Set<AnyCancellable>()
        try await confirmation { confirmation in
            await repository
                .friendsUpdated(ofKind: set)
                .sink { friendsFromPublisher in
                    #expect(friendsFromPublisher == friendsCasted)
                    confirmation()
                }
                .store(in: &subscriptions)
            let friendsFromRepository = try await repository.refreshFriends(ofKind: set)
            #expect(friendsFromRepository == friendsCasted)
            try await taskFactory.runUntilIdle()
        }

        // then

        #expect(await provider.getUsersCalls.map { Set($0) } == [Set(friends.values.flatMap { $0 }.map(\.id))])
        #expect(await provider.getFriendsCalls == [ set.array.map(FriendshipKindDto.init).map(\.rawValue) ])
        #expect(await offlineRepository.updates.map(\.0) == [friendsCasted])
        #expect(await offlineRepository.updates.map(\.1) == [set])
    }

    @Test func testFriendsPolling() async throws {

        // given

        let taskFactory = TestTaskFactory()
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
            getUsersResponse: friends.values.flatMap { $0.map(UserDto.init) }
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultFriendsRepository(
            api: provider.api,
            longPoll: provider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )
        let friendsCasted: [FriendshipKind: [User]] = friends.reduce(into: [:]) { dict, kv in
            guard let key = FriendshipKindDto(rawValue: kv.key) else {
                return
            }
            dict[FriendshipKind(dto: key)] = kv.value
        }

        // when

        var subscriptions = Set<AnyCancellable>()
        try await confirmation { confirmation in
            await repository
                .friendsUpdated(ofKind: set)
                .dropFirst()
                .sink { friendsFromPublisher in
                    #expect(friendsFromPublisher == friendsCasted)
                    confirmation()
                }
                .store(in: &subscriptions)
            provider.getFriendsSubject.send(
                LongPollFriendsQuery.Update(category: .friends)
            )
            try await taskFactory.runUntilIdle()
        }

        // then

        #expect(await provider.getUsersCalls.map { Set($0) } == [Set(friends.values.flatMap { $0 }.map(\.id))])
        #expect(await provider.getFriendsCalls == [ set.array.map(FriendshipKindDto.init).map(\.rawValue) ])
        #expect(await offlineRepository.updates.map(\.0) == [friendsCasted])
        #expect(await offlineRepository.updates.map(\.1) == [set])
    }
}
