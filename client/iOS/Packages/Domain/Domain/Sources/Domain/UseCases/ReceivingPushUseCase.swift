import Foundation
import UserNotifications

public struct PushContent {
    public let title: String
    public let subtitle: String
    public let body: String

    public init(title: String, subtitle: String, body: String) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
    }
}

public enum ProcessPushError: Error {
    case internalError(Error)
}

public protocol ReceivingPushUseCase {
    func process(rawPushPayload: [AnyHashable: Any]) async throws(ProcessPushError) -> PushContent
}
