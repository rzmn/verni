import Domain
import Api
import Combine
import Logging
internal import Base
internal import DataTransferObjects
internal import ApiDomainConvenience

public class DefaultFriendsRepository {
    public let logger: Logger

    private let api: ApiProtocol
    private let offline: FriendsOfflineMutableRepository
    private let longPoll: LongPoll
    private var subjects = [FriendshipKindSet: PassthroughSubject<[FriendshipKind: [User]], Never>]()

    public init(api: ApiProtocol, longPoll: LongPoll, logger: Logger, offline: FriendsOfflineMutableRepository) {
        self.api = api
        self.offline = offline
        self.longPoll = longPoll
        self.logger = logger
    }
}

extension DefaultFriendsRepository: FriendsRepository {
    private func subject(for kind: FriendshipKindSet) -> PassthroughSubject<[FriendshipKind: [User]], Never> {
        guard let subject = subjects[kind] else {
            logI { "subject created for \(kind)" }
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
                    logI { "got lp [friendsUpdated, kind=\(kind)], refreshing data" }
                    Task.detached {
                        let result = await self.refreshFriends(ofKind: kind)
                        switch result {
                        case .success(let friends):
                            self.logI { "got lp [friendsUpdated, kind=\(kind)], refreshing data OK" }
                            promise(.success(friends))
                        case .failure(let error):
                            self.logI { "got lp [friendsUpdated, kind=\(kind)], refreshing data error: \(error), skip" }
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
        logI { "refreshFriends[kind=\(kind)]" }
        let uids: [UserDto.ID]
        do {
            uids = try await api.run(
                method: Friends.Get(
                    statuses: kind.array.map(FriendshipKindDto.init)
                )
            ).flatMap(\.value)
        } catch {
            logI { "refreshFriends[kind=\(kind)] error: \(error)" }
            return .failure(GeneralError(apiError: error))
        }
        let users: [UserDto]
        do {
            users = try await api.run(method: Users.Get(ids: uids))
        } catch {
            logI { "refreshFriends[kind=\(kind)] get users error: \(error)" }
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

extension DefaultFriendsRepository: Loggable {}
