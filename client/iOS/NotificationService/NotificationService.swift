import UserNotifications
import DefaultDependencies
import Domain
import DI

class NotificationService: UNNotificationServiceExtension {
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        Task {
            await process(request: request, handler: contentHandler)
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
        let session: ActiveSessionDIContainer
        do {
            session = try await DefaultDependenciesAssembly().authUseCase().awake()
        } catch {
            return
        }
        let pushContent: PushContent
        do {
            pushContent = try await session
                .receivingPushUseCase()
                .process(rawPushPayload: content.userInfo)
        } catch {
            return
        }
        content.title = pushContent.title
        content.subtitle = pushContent.subtitle
        content.body = pushContent.body
    }
}
