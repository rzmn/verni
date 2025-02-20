import Foundation

public struct ErrorContext<T: Sendable>: Sendable, Error {
    public let context: T
    
    public init(context: T) {
        self.context = context
    }
}

public struct UndocumentedBehaviour<T: Sendable>: Sendable, Error {
    public let context: T

    public init(context: T) {
        self.context = context
    }
}

public enum InternalError: Error, Equatable, CustomStringConvertible {
    public static func == (lhs: InternalError, rhs: InternalError) -> Bool {
        lhs.description == rhs.description
    }
    
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
