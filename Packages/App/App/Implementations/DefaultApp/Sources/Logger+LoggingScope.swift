internal import Logging

enum LoggingScope: CustomStringConvertible {
    case dataLayer
    case saveCredentials
    case images
    case users
    case spendings
    case auth
    case pushNotifications
    case emailConfirmation
    case qrCode
    case profile
    case logout
    
    var description: String {
        switch self {
        case .dataLayer:
            "🗄️"
        case .saveCredentials:
            "🔐"
        case .images:
            "🧑‍🎨"
        case .users:
            "🪪"
        case .spendings:
            "💸"
        case .auth:
            "🛂"
        case .pushNotifications:
            "🔔"
        case .emailConfirmation:
            "📧"
        case .qrCode:
            "🌃"
        case .profile:
            "🆔"
        case .logout:
            "🚪"
        }
    }
}

extension Logger {
    func with(scope: LoggingScope) -> Logger {
        with(prefix: scope.description)
    }
}
