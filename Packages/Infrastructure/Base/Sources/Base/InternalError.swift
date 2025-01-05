import Foundation

public struct ErrorContext<T: Sendable>: Sendable, Error {
    public let context: T
    
    public init(context: T) {
        self.context = context
    }
}

public enum InternalError: Error, CustomStringConvertible {
    case error(String, underlying: Error? = nil)

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
