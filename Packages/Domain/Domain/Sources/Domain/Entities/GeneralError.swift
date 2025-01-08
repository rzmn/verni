public enum GeneralError: Error, CustomStringConvertible, Sendable {
    case noConnection(Error)
    case notAuthorized(Error)
    case other(Error)
}

extension GeneralError {
    public var description: String {
        switch self {
        case .noConnection(let error):
            return "no connection: \(error)"
        case .other(let error):
            return "internal error: \(error)"
        case .notAuthorized(let error):
            return "not authorized: \(error)"
        }
    }
}
