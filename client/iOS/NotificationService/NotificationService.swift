import UserNotifications
import DefaultDependencies
import Domain
import DI

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
        let session: ActiveSessionDIContainer
        do {
            session = try await DefaultDependenciesAssembly().authUseCase().awake()
        } catch {
            return
        }
        let pushProcessResult = await session
            .receivingPushUseCase()
            .process(rawPushPayload: content.userInfo)
        let pushContent: PushContent
        switch pushProcessResult {
        case .success(let result):
            pushContent = result
        case .failure:
            return
        }
        content.title = pushContent.title
        content.subtitle = pushContent.subtitle
        content.body = pushContent.body
    }
}
