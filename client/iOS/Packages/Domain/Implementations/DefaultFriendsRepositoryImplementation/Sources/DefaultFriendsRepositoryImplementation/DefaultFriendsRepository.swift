import Domain
import Api
import Combine
internal import Base
internal import DataTransferObjects
internal import ApiDomainConvenience

public class DefaultFriendsRepository {
    private let api: ApiProtocol
    private let offline: FriendsOfflineMutableRepository

    public lazy var friendsUpdated = createFriendsUpdatedSubject()
    private var friendsSubscribersCount = 0

    public init(api: ApiProtocol, offline: FriendsOfflineMutableRepository) {
        self.api = api
        self.offline = offline
    }
}

extension DefaultFriendsRepository {
    private func createFriendsUpdatedSubject() -> AnyPublisher<Void, Never> {
        PassthroughSubject<Void, Never>()
            .handleEvents(
                receiveSubscription: weak(self, type(of: self).spendingCounterpartiesSubscribed) • nop,
                receiveCompletion: weak(self, type(of: self).spendingCounterpartiesUnsubscribed) • nop,
                receiveCancel: weak(self, type(of: self).spendingCounterpartiesUnsubscribed)
            )
            .eraseToAnyPublisher()
    }

    private func spendingCounterpartiesSubscribed() {
        friendsSubscribersCount += 1
    }

    private func spendingCounterpartiesUnsubscribed() {
        friendsSubscribersCount -= 1
    }
}

extension DefaultFriendsRepository: FriendsRepository {
    public func getFriends(set: Set<FriendshipKind>) async -> Result<[FriendshipKind: [User]], GeneralError> {
        let uids: [UserDto.ID]
        switch await api.run(
            method: Friends.Get(
                statuses: FriendshipKind.allCases
                    .filter(set.contains)
                    .map(FriendshipKindDto.init)
            )
        ) {
        case .success(let dict):
            uids = dict.flatMap(\.value)
        case .failure(let apiError):
            return .failure(GeneralError(apiError: apiError))
        }
        let users: [UserDto]
        switch await api.run(method: Users.Get(ids: uids)) {
        case .success(let success):
            users = success
        case .failure(let error):
            return .failure(GeneralError(apiError: error))
        }
        let friendsByKind = users.map(User.init).reduce(
            into: set.reduce(into: [:], { dict, value in dict[value] = [User]() })
        ) { dict, user in
            switch user.status {
            case .me, .no:
                break
            case .outgoing:
                var array = dict[.pending] ?? []
                array.append(user)
                dict[.pending] = array
            case .incoming:
                var array = dict[.incoming] ?? []
                array.append(user)
                dict[.incoming] = array
            case .friend:
                var array = dict[.friends] ?? []
                array.append(user)
                dict[.friends] = array
            }
        } as [FriendshipKind: [User]]
        Task.detached { [weak self] in
            guard let self else { return }
            await offline.storeFriends(friendsByKind)
        }
        return .success(friendsByKind)
    }
}
