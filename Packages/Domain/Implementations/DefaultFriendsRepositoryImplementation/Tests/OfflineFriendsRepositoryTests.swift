import Testing
import PersistentStorage
import DataTransferObjects
import Foundation
import Base
import Domain
import ApiDomainConvenience
@testable import DefaultFriendsRepositoryImplementation
@testable import MockPersistentStorage

private extension FriendshipKindSet {
    init(_ set: FriendshipKindSetDto) {
        var result: FriendshipKindSet = []
        for element in set.array {
            switch element {
            case .friends:
                result.insert(.friends)
            case .subscription:
                result.insert(.subscription)
            case .subscriber:
                result.insert(.subscriber)
            }
        }
        self = result
    }
}

private actor PersistencyProvider {
    let persistency: PersistencyMock
    var getFriendsCalls: [FriendshipKindSet] = []
    var updateFriendsCalls: [(FriendshipKindSet, FriendsData)] = []
    typealias FriendsData = [FriendshipKind: [User]]
    var friends = [FriendshipKindSet: FriendsData]()

    init() async {
        persistency = PersistencyMock()
        await persistency.performIsolated { persistency in
            persistency.getBlock = { anyDescriptor in
                guard let descriptor = anyDescriptor as? Descriptor<FriendshipKindSetDto, [FriendshipKindDto: [UserDto]]>.Index else {
                    fatalError()
                }
                await self.performIsolated { `self` in
                    self.getFriendsCalls.append(FriendshipKindSet(descriptor.key))
                }
                return await self.friends[FriendshipKindSet(descriptor.key)]?.reduce(into: [:], { dict, kv in
                    dict[FriendshipKindDto(domain: kv.key)] = kv.value.map(UserDto.init)
                })
            }
            persistency.updateBlock = { anyDescriptor, anyObject in
                guard let descriptor = anyDescriptor as? Descriptor<FriendshipKindSetDto, [FriendshipKindDto: [UserDto]]>.Index, let friends = anyObject as? [FriendshipKindDto: [UserDto]] else {
                    fatalError()
                }
                let kindToSet = FriendshipKindSet(descriptor.key)
                let friendsToSet = friends.reduce(into: [:], { dict, kv in
                    dict[FriendshipKind(dto: kv.key)] = kv.value.map(User.init)
                })
                self.performIsolated { `self` in
                    self.updateFriendsCalls.append((kindToSet, friendsToSet))
                    self.friends[kindToSet] = friendsToSet
                }
            }
        }
    }
}

@Suite struct OfflineProfileRepositoryTests {

    @Test func testGetNoFriends() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultFriendsOfflineRepository(persistency: provider.persistency)

        // when

        let friends = await repository.getFriends(set: .all)

        // then

        #expect(friends == nil)
        #expect(await provider.getFriendsCalls == [.all])
    }

    @Test func testSetUser() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultFriendsOfflineRepository(persistency: provider.persistency)
        let friendshipKindSet: FriendshipKindSet = [.friends, .subscriber]
        let friends: [FriendshipKind: [User]] = [
            .friends: [
                User(
                    id: UUID().uuidString,
                    status: .friend,
                    displayName: "some name",
                    avatar: nil
                )
            ]
        ]

        // when

        await repository.storeFriends(friends, for: friendshipKindSet)
        let friendsFromRepository = await repository.getFriends(set: friendshipKindSet)
        let profileFromRepositoryAnotherQuery = await repository.getFriends(set: [.friends])

        // then

        #expect(friendsFromRepository == friends)
        #expect(profileFromRepositoryAnotherQuery == nil)
        #expect(await provider.getFriendsCalls == [friendshipKindSet, [.friends]])
        #expect(await provider.updateFriendsCalls.map(\.0) == [friendshipKindSet])
        #expect(await provider.updateFriendsCalls.map(\.1) == [friends])
    }
}
