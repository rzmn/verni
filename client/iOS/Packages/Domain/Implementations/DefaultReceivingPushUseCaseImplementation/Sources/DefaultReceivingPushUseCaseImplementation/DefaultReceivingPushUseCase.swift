import Domain
import Foundation
import Logging
import UserNotifications
internal import Base

public class DefaultReceivingPushUseCase {
    public let logger: Logger

    private let usersRepository: UsersRepository
    private let friendsRepository: FriendsRepository
    private let spendingsRepository: SpendingsRepository

    private lazy var decoder = JSONDecoder()

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
    public func process(rawPushPayload: [AnyHashable: Any]) async -> Result<PushContent, ProcessPushError> {
        let userData: Data
        do {
            userData = try JSONSerialization.data(withJSONObject: rawPushPayload)
        } catch {
            logE { "failed to convert userData into data due error: \(error). userData=\(rawPushPayload)" }
            return .failure(.internalError(InternalError.error("failed to convert userData into data", underlying: error)))
        }
        let payload: PushPayload
        do {
            payload = try decoder.decode(Push.self, from: userData).payload
        } catch {
            logE { "failed to convert push data due error: \(error). userData=\(rawPushPayload)" }
            return .failure(.internalError(InternalError.error("failed to convert push data to typed data", underlying: error)))
        }
        switch payload {
        case .friendRequestHasBeenAccepted(let payload):
            Task.detached {
                await self.friendsRepository.refreshFriends(ofKind: .all)
            }
            let users: [User]
            switch await usersRepository.getUsers(ids: [payload.target]) {
            case .success(let result):
                users = result
            case .failure(let error):
                logE { "failed to get info error: \(error)" }
                return .failure(.internalError(InternalError.error("failed to get user info", underlying: error)))
            }
            guard let user = users.first else {
                logE { "user does not exists" }
                return .failure(.internalError(InternalError.error("user does not exists", underlying: nil)))
            }
            return .success(
                PushContent(
                    title: "friendRequestHasBeenAccepted",
                    subtitle: "subtitle!!",
                    body: "from: \(user.displayName)"
                )
            )
        case .gotFriendRequest(let payload):
            Task.detached {
                await self.friendsRepository.refreshFriends(ofKind: .all)
            }
            let users: [User]
            switch await usersRepository.getUsers(ids: [payload.sender]) {
            case .success(let result):
                users = result
            case .failure(let error):
                logE { "failed to get info error: \(error)" }
                return .failure(.internalError(InternalError.error("failed to get user info", underlying: error)))
            }
            guard let user = users.first else {
                logE { "user does not exists" }
                return .failure(.internalError(InternalError.error("user does not exists", underlying: nil)))
            }
            return .success(
                PushContent(
                    title: "gotFriendRequest",
                    subtitle: "subtitle!!",
                    body: "from: \(user.displayName)"
                )
            )
        case .newExpenseReceived(let payload):
            Task.detached {
                await [
                    self.spendingsRepository.refreshSpendingCounterparties(),
                    self.spendingsRepository.refreshSpendingsHistory(counterparty: payload.authorId)
                ]
            }
            let spending: Spending
            switch await spendingsRepository.getSpending(id: payload.spendingId) {
            case .success(let result):
                spending = result
            case .failure(let error):
                logE { "failed to get info error: \(error)" }
                return .failure(.internalError(InternalError.error("failed to get spending info", underlying: error)))
            }
            return .success(
                PushContent(
                    title: "newExpenseReceived",
                    subtitle: "subtitle!!",
                    body: "\(spending.details)"
                )
            )
        }
    }
}

extension DefaultReceivingPushUseCase: Loggable {}
