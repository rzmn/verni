public enum ApiServiceError: Error {
    case noConnection(Error)
    case decodingFailed(Error)
    case internalError(Error)
}

extension ApiServiceError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .noConnection:
            return "no connection"
        case .decodingFailed(let error):
            return "decoding failed due error: \(error)"
        case .internalError(let error):
            return "internal error: \(error)"
        }
    }
}
