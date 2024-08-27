import Foundation

public enum InternalError: Error, CustomStringConvertible {
    case error(String, underlying: Error?)

    public var description: String {
        switch self {
        case .error(let description, let underlying):
            if let underlying {
                return "internal[desc=\(description), underlying\(underlying)]"
            } else {
                return "internal[desc=\(description)]"
            }
        }
    }
}
