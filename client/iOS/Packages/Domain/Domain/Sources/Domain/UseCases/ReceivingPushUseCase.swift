import Foundation
import UserNotifications

public protocol ReceivingPushUseCase {
    func process(request: UNNotificationRequest) async -> UNNotificationContent
}
