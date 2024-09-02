public enum HttpCode: Sendable {
    public enum Succcess: Sendable {
        case ok
        case created
        case other(Int)

        init(code: Int) {
            switch code {
            case 200:
                self = .ok
            case 201:
                self = .created
            default:
                self = .other(code)
            }
        }
    }
    public enum ClientError: Sendable {
        case badRequest
        case conflict
        case unauthorized
        case other(Int)

        init(code: Int) {
            switch code {
            case 400:
                self = .badRequest
            case 401:
                self = .unauthorized
            case 409:
                self = .conflict
            default:
                self = .other(code)
            }
        }
    }
    public enum ServerError: Sendable {
        case internalServerError
        case other(Int)

        init(code: Int) {
            switch code {
            case 500:
                self = .internalServerError
            default:
                self = .other(code)
            }
        }
    }

    case success(Succcess)
    case clientError(ClientError)
    case serverError(ServerError)
    case unknown(Int)

    public init(code: Int) {
        switch code {
        case 200 ..< 300:
            self = .success(Succcess(code: code))
        case 400 ..< 500:
            self = .clientError(ClientError(code: code))
        case 500 ..< 600:
            self = .serverError(ServerError(code: code))
        default:
            self = .unknown(code)
        }
    }


    public var success: Bool {
        guard case .success = self else {
            return false
        }
        return true
    }
}
