import Foundation
import UserNotifications
internal import Base

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

public enum ProcessPushError: Error, CustomStringConvertible {
    case internalError(Error)

    public var description: String {
        switch self {
        case .internalError(let error):
            if let error = error as? InternalError, case .error(let string, let underlying) = error {
                return "\(string) [\(String(describing: underlying))]"
            } else {
                return error.localizedDescription
            }
        }
    }
}

public protocol ReceivingPushUseCase {
    func process(rawPushPayload: [AnyHashable: Any]) async -> Result<PushContent, ProcessPushError>
}
