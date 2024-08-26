import UserNotifications
import App
import DefaultDependencies

class NotificationService: UNNotificationServiceExtension {
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        Task.detached { [weak self] in
            guard let self else { return }
            guard case .success(let session) = await DefaultDependenciesAssembly().authUseCase().awake() else {
                return
            }
            contentHandler(await session.receivingPushUseCase().process(request: request))
        }
    }
}
