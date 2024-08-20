import Domain
import Api
import Combine
internal import Base
internal import DataTransferObjects
internal import ApiDomainConvenience

public class DefaultFriendsRepository {
    private let api: ApiProtocol
    private let offline: FriendsOfflineMutableRepository
    private let longPoll: LongPoll

    public init(api: ApiProtocol, longPoll: LongPoll, offline: FriendsOfflineMutableRepository) {
        self.api = api
        self.offline = offline
        self.longPoll = longPoll
    }
}

extension DefaultFriendsRepository: FriendsRepository {
    public func friendsUpdated() async -> AnyPublisher<Void, Never> {
        await longPoll.create(for: LongPollFriendsQuery())
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
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
