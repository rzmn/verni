import UserNotifications
import DefaultDependencies

class NotificationService: UNNotificationServiceExtension {
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        Task.detached {
            await self.process(request: request, handler: contentHandler)
        }
    }

    private func process(
        request: UNNotificationRequest,
        handler: @escaping (UNNotificationContent) -> Void
    ) async {
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return handler(request.content)
        }
        defer {
            handler(content)
        }
        let awakeResult = await DefaultDependenciesAssembly()
            .authUseCase()
            .awake()
        guard case .success(let session) = awakeResult else {
            return
        }
        let pushContent = await session.receivingPushUseCase().process(rawPushPayload: content.userInfo)
        guard let pushContent else {
            return
        }
        content.title = pushContent.title
        content.subtitle = pushContent.subtitle
        content.body = pushContent.body
    }
}
