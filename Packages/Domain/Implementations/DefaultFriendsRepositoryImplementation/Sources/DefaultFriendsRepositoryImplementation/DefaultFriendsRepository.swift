import Domain
import Api
import Combine
import Logging
import Base
internal import DataTransferObjects
internal import ApiDomainConvenience

public actor DefaultFriendsRepository {
    public let logger: Logger

    private let api: ApiProtocol
    private let offline: FriendsOfflineMutableRepository
    private let longPoll: LongPoll
    private let taskFactory: TaskFactory
    private var subjects = [FriendshipKindSet: PassthroughSubject<[FriendshipKind: [User]], Never>]()

    public init(
        api: ApiProtocol,
        longPoll: LongPoll,
        logger: Logger,
        offline: FriendsOfflineMutableRepository,
        taskFactory: TaskFactory
    ) {
        self.api = api
        self.offline = offline
        self.longPoll = longPoll
        self.logger = logger
        self.taskFactory = taskFactory
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
                Future { (promise: @escaping (Result<[FriendshipKind: [User]]?, Never>) -> Void) in
                    self.logI { "got lp [friendsUpdated, kind=\(kind)], refreshing data" }
                    Task {
                        let result = try? await self.refreshFriends(ofKind: kind)
                        promise(.success(result))
                    }
                }
            }
            .compactMap { $0 }
            .merge(with: subject(for: kind))
            .eraseToAnyPublisher()
    }

    public func refreshFriends(ofKind kind: FriendshipKindSet) async throws(GeneralError) -> [FriendshipKind: [User]] {
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
            throw GeneralError(apiError: error)
        }
        let users: [UserDto]
        do {
            users = try await api.run(method: Users.Get(ids: uids))
        } catch {
            logI { "refreshFriends[kind=\(kind)] get users error: \(error)" }
            throw GeneralError(apiError: error)
        }
        let friendsByKind = users.map(User.init).reduce(
            into: kind.array.reduce(into: [:], { dict, value in dict[value] = [User]() })
        ) { dict, user in
            switch user.status {
            case .me, .no:
                break
            case .outgoing:
                var array = dict[.subscription] ?? []
                array.append(user)
                dict[.subscription] = array
            case .incoming:
                var array = dict[.subscriber] ?? []
                array.append(user)
                dict[.subscriber] = array
            case .friend:
                var array = dict[.friends] ?? []
                array.append(user)
                dict[.friends] = array
            }
        } as [FriendshipKind: [User]]
        taskFactory.detached {
            await self.offline.storeFriends(friendsByKind, for: kind)
        }
        subject(for: kind).send(friendsByKind)
        return friendsByKind
    }
}

extension DefaultFriendsRepository: Loggable {}
