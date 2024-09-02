import Domain
import Foundation
import Logging
import UserNotifications
internal import Base

public actor DefaultReceivingPushUseCase {
    public let logger: Logger

    private let usersRepository: UsersRepository
    private let friendsRepository: FriendsRepository
    private let spendingsRepository: SpendingsRepository

    private let decoder = JSONDecoder()

    public init(
        usersRepository: UsersRepository,
        friendsRepository: FriendsRepository,
        spendingsRepository: SpendingsRepository,
        logger: Logger
    ) {
        self.logger = logger
        self.usersRepository = usersRepository
        self.friendsRepository = friendsRepository
        self.spendingsRepository = spendingsRepository
    }
}

extension DefaultReceivingPushUseCase: ReceivingPushUseCase {
    public nonisolated func process(rawPushPayload: [AnyHashable: Any]) async throws(ProcessPushError) -> PushContent {
        let userData: Data
        do {
            userData = try JSONSerialization.data(withJSONObject: rawPushPayload)
        } catch {
            logE { "failed to convert userData into data due error: \(error). userData=\(rawPushPayload)" }
            throw .internalError(InternalError.error("failed to convert userData into data", underlying: error))
        }
        let payload: PushPayload
        do {
            payload = try decoder.decode(Push.self, from: userData).payload
        } catch {
            logE { "failed to convert push data due error: \(error). userData=\(rawPushPayload)" }
            throw .internalError(InternalError.error("failed to convert push data to typed data", underlying: error))
        }
        switch payload {
        case .friendRequestHasBeenAccepted(let payload):
            Task.detached {
                try? await self.friendsRepository.refreshFriends(ofKind: .all)
            }
            let user: User
            do {
                user = try await usersRepository.getUser(id: payload.target)
            } catch {
                logE { "failed to get info error: \(error)" }
                throw .internalError(InternalError.error("failed to get user info", underlying: error))
            }
            return PushContent(
                title: "friendRequestHasBeenAccepted",
                subtitle: "subtitle!!",
                body: "from: \(user.displayName)"
            )
        case .gotFriendRequest(let payload):
            Task.detached {
                try? await self.friendsRepository.refreshFriends(ofKind: .all)
            }
            let user: User
            do {
                user = try await usersRepository.getUser(id: payload.sender)
            } catch {
                logE { "failed to get info error: \(error)" }
                throw .internalError(InternalError.error("failed to get user info", underlying: error))
            }
            return PushContent(
                title: "gotFriendRequest",
                subtitle: "subtitle!!",
                body: "from: \(user.displayName)"
            )
        case .newExpenseReceived(let payload):
            Task.detached {
                try? await [
                    self.spendingsRepository.refreshSpendingCounterparties(),
                    self.spendingsRepository.refreshSpendingsHistory(counterparty: payload.authorId)
                ]
            }
            let spending: Spending
            do {
                spending = try await spendingsRepository.getSpending(id: payload.spendingId)
            } catch {
                logE { "failed to get info error: \(error)" }
                throw .internalError(InternalError.error("failed to get spending info", underlying: error))
            }
            return PushContent(
                title: "newExpenseReceived",
                subtitle: "subtitle!!",
                body: "\(spending.details)"
            )
        }
    }
}

extension DefaultReceivingPushUseCase: Loggable {}
