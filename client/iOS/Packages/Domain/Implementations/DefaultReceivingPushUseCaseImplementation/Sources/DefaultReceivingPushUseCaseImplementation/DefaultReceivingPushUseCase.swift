import Domain
import Foundation
import Logging
import UserNotifications

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
    public func process(request: UNNotificationRequest) async -> UNNotificationContent {
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return request.content
        }
        let userData: Data
        do {
            userData = try JSONSerialization.data(withJSONObject: request.content.userInfo)
        } catch {
            logE { "failed to convert userData into data due error: \(error). userData=\(request.content.userInfo)" }
            return content
        }
        let payload: PushPayload
        do {
            payload = try decoder.decode(PushPayload.self, from: userData)
        } catch {
            logE { "failed to convert push data due error: \(error). userData=\(request.content.userInfo)" }
            return content
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
                return request.content
            }
            guard let user = users.first else {
                logE { "user does not exists" }
                return request.content
            }
            content.title = "friendRequestHasBeenAccepted"
            content.subtitle = "subtitle!!"
            content.body = "from: \(user.displayName)"
            return content
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
                return request.content
            }
            guard let user = users.first else {
                logE { "user does not exists" }
                return request.content
            }
            content.title = "gotFriendRequest"
            content.subtitle = "subtitle!!"
            content.body = "from: \(user.displayName)"
            return content
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
                return request.content
            }
            content.title = "newExpenseReceived"
            content.subtitle = "subtitle!!"
            content.body = "\(spending.details)"
            return content
        }
    }
}

extension DefaultReceivingPushUseCase: Loggable {}
