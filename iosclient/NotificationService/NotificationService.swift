import UserNotifications
import Assembly

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        Task {
            await process(request: request, handler: contentHandler)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}

extension NotificationService {
    @MainActor private func process(
        request: UNNotificationRequest,
        handler: @escaping (UNNotificationContent) -> Void
    ) async {
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return handler(request.content)
        }
        bestAttemptContent = content
        defer {
            handler(content)
        }
        let assembly: Assembly
        do {
            assembly = try Assembly()
        } catch {
            return
        }
        await assembly.appModel.handle(push: content)
    }
}
