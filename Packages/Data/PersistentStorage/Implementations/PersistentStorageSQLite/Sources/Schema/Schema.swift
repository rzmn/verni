import Api

enum Schema {
    case operations
    case refreshToken
    case deviceId

    var tableName: String {
        switch self {
        case .operations:
            "operations"
        case .refreshToken:
            "refreshToken"
        case .deviceId:
            "deviceId"
        }
    }

    var identifierKey: String {
        "id"
    }

    var valueKey: String {
        "value"
    }
}
