import Domain
import Api
import Logging
import Base
import AsyncExtensions
import OnDemandPolling
internal import DataTransferObjects
internal import ApiDomainConvenience

private struct BroadcastWithOnDemandLongPoll<T: Sendable, Q: LongPollQuery> {
    let broadcast: AsyncBroadcast<T>
    private let subscription: OnDemandLongPollSubscription<T, Q>
    init(
        longPoll: LongPoll,
        taskFactory: TaskFactory,
        query: Q,
        logger: Logger = .shared
    ) async where Q.Update: Decodable {
        broadcast = AsyncBroadcast(
            taskFactory: taskFactory
        )
        subscription = await OnDemandLongPollSubscription(
            subscribersCount: broadcast.subscribersCount,
            longPoll: longPoll,
            taskFactory: taskFactory,
            query: query,
            logger: logger
        )
    }

    func start(onLongPoll: @escaping @Sendable (Q.Update) -> Void) async {
        await subscription.start(onLongPoll: onLongPoll)
    }
}

public actor DefaultFriendsRepository {
    public let logger: Logger

    private let api: ApiProtocol
    private let offline: FriendsOfflineMutableRepository
    private let longPoll: LongPoll
    private let taskFactory: TaskFactory
    private var subjects = [FriendshipKindSet: BroadcastWithOnDemandLongPoll<[FriendshipKind: [User]], LongPollFriendsQuery>]()

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
    private func subject(
        for kind: FriendshipKindSet
    ) async -> BroadcastWithOnDemandLongPoll<[FriendshipKind: [User]], LongPollFriendsQuery> {
        guard let subject = subjects[kind] else {
            logI { "subject created for \(kind)" }
            let subject = await BroadcastWithOnDemandLongPoll<[FriendshipKind: [User]], LongPollFriendsQuery>(
                longPoll: longPoll,
                taskFactory: taskFactory,
                query: LongPollFriendsQuery()
            )
            await subject.start { update in
                self.taskFactory.task {
                    try? await self.refreshFriends(ofKind: kind)
                }
            }
            subjects[kind] = subject
            return subject
        }
        return subject
    }

    public func friendsUpdated(ofKind kind: FriendshipKindSet) async -> any AsyncPublisher<[FriendshipKind: [User]]> {
        await subject(for: kind).broadcast
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
        await subject(for: kind).broadcast.yield(friendsByKind)
        return friendsByKind
    }
}

extension DefaultFriendsRepository: Loggable {}
