import Foundation

public enum LongPollError: Error, CustomStringConvertible {
    case noUpdates
    case noConnection(Error)
    case internalError(Error)

    public var description: String {
        switch self {
        case .noUpdates:
            return "no updates"
        case .noConnection(let error):
            return "no connection: \(error)"
        case .internalError(let error):
            return "internal error: \(error)"
        }
    }
}
