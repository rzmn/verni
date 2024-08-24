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
    private var subjects = [FriendshipKindSet: PassthroughSubject<[FriendshipKind: [User]], Never>]()

    public init(api: ApiProtocol, longPoll: LongPoll, offline: FriendsOfflineMutableRepository) {
        self.api = api
        self.offline = offline
        self.longPoll = longPoll
    }
}

extension DefaultFriendsRepository: FriendsRepository {
    private func subject(for kind: FriendshipKindSet) -> PassthroughSubject<[FriendshipKind: [User]], Never> {
        guard let subject = subjects[kind] else {
            let subject = PassthroughSubject<[FriendshipKind: [User]], Never>()
            subjects[kind] = subject
            return subject
        }
        return subject
    }

    public func friendsUpdated(ofKind kind: FriendshipKindSet) async -> AnyPublisher<[FriendshipKind: [User]], Never> {
        await longPoll.poll(for: LongPollFriendsQuery())
            .flatMap { _ in
                Future { [weak self] (promise: @escaping (Result<[FriendshipKind: [User]]?, Never>) -> Void) in
                    guard let self else {
                        return promise(.success(nil))
                    }
                    Task.detached {
                        let result = await self.refreshFriends(ofKind: kind)
                        switch result {
                        case .success(let friends):
                            promise(.success(friends))
                        case .failure:
                            promise(.success(nil))
                        }
                    }
                }
            }
            .compactMap { $0 }
            .merge(with: subject(for: kind))
            .eraseToAnyPublisher()
    }
    
    public func refreshFriends(ofKind kind: FriendshipKindSet) async -> Result<[FriendshipKind: [User]], GeneralError> {
        let uids: [UserDto.ID]
        switch await api.run(
            method: Friends.Get(
                statuses: kind.array.map(FriendshipKindDto.init)
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
            into: kind.array.reduce(into: [:], { dict, value in dict[value] = [User]() })
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
        subject(for: kind).send(friendsByKind)
        return .success(friendsByKind)
    }
}
