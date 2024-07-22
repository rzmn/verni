import Domain
import Api
import DataTransferObjects
import PersistentStorage
internal import ApiDomainConvenience

public class DefaultFriendsRepository {
    private let api: Api
    private let persistency: Persistency

    public init(api: Api, persistency: Persistency) {
        self.api = api
        self.persistency = persistency
    }
}

extension DefaultFriendsRepository: FriendsRepository {
    public var friendsUpdated: AsyncStream<Void> {
        api.friendsUpdated
    }
    
    public func getFriends(set: Set<FriendshipKind>) async -> Result<[FriendshipKind: [User]], GeneralError> {
        let result = await api.getFriends(
            kinds: FriendshipKind.allCases
                .filter(set.contains)
                .map(FriendshipKindDto.init)
        )
        let uids: [UserDto.ID]
        switch result {
        case .success(let dict):
            uids = dict.flatMap(\.value)
        case .failure(let apiError):
            return .failure(GeneralError(apiError: apiError))
        }
        let users: [UserDto]
        switch await api.getUsers(uids: uids) {
        case .success(let success):
            users = success
        case .failure(let error):
            return .failure(GeneralError(apiError: error))
        }
        let friendsByKind = users.map(User.init).reduce(into: [:], { dict, user in
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
        }) as [FriendshipKind: [User]]
        Task.detached { [weak self] in
            guard let self else { return }
            await persistency.storeFriends(friendsByKind)
        }
        return .success(friendsByKind)
    }
}
