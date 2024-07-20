import Domain
import Api
import Combine
internal import ApiDomainConvenience

public class DefaultFriendsRepository {
    private let api: Api

    public init(api: Api) {
        self.api = api
    }
}

extension DefaultFriendsRepository: FriendsRepository {
    public var friendsUpdated: AnyPublisher<Void, Never> {
        api.friendsUpdated.eraseToAnyPublisher()
    }
    
    public func getFriends(set: FriendshipKindSet) async -> Result<[FriendshipKind: [User]], GeneralError> {
        let result = await api.getFriends(
            kinds: FriendshipKind.allCases
                .filter({ set.contains(FriendshipKindSet(element: $0)) })
                .map { kind in
                    switch kind {
                    case .friends:
                        return .friends
                    case .incoming:
                        return .subscriber
                    case .pending:
                        return .subscription
                    }
                }
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
        return .success(
            users.map { user in
                User(id: user.login, status: {
                    switch user.friendStatus {
                    case .no:
                        return .no
                    case .incomingRequest:
                        return .incoming
                    case .outgoingRequest:
                        return .outgoing
                    case .friends:
                        return .friend
                    case .me:
                        return .me
                    }
                }())
            }.reduce(into: [:], { dict, user in
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
            })
        )
    }
}
