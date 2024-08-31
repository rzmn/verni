public enum NetworkServiceError: Error {
    case cannotBuildRequest(Error)
    case cannotSend(Error)
    case badResponse(Error)
    case noConnection(Error)
}

extension NetworkServiceError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cannotBuildRequest(let error):
            return "cannot build req due error: \(error)"
        case .cannotSend(let error):
            return "cannot send req due error: \(error)"
        case .badResponse(let error):
            return "cannot handle response due error: \(error)"
        case .noConnection(let error):
            return "connection lost: \(error)"
        }
    }
}
