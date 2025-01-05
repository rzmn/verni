public enum ApiServiceError: Error, Sendable {
    case noConnection(Error)
    case internalError(Error)
    case unauthorized
}

extension ApiServiceError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .noConnection:
            return "no connection"
        case .internalError(let error):
            return "internal error: \(error)"
        case .unauthorized:
            return "unauthorized"
        }
    }
}
