import Domain
import Foundation
import Logging
import UserNotifications

public class DefaultReceivingPushUseCase {
    public let logger: Logger

    private lazy var decoder = JSONDecoder()

    public init(
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository,
        logger: Logger
    ) {
        self.logger = logger
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
        }
        let payload: PushPayload
        do {
            let payload = try decoder.decode(PushPayload.self, from: userData)
        } catch {
            logE { "failed to convert push data due error: \(error). userData=\(request.content.userInfo)" }
        }
        switch payload {
        case .friendRequestHasBeenAccepted(let payload):
            break
        case .gotFriendRequest(let payload):
            break
        case .newExpenseReceived(let payload):
            break
        }
    }
}

extension DefaultReceivingPushUseCase: Loggable {}
