import AppBase
import Foundation
import UserNotifications

public protocol AppModel: Sendable {
    @MainActor func view() -> AppView
    
    func registerPushToken(token: Data) async
    @MainActor func handle(push: UNMutableNotificationContent) async
}
