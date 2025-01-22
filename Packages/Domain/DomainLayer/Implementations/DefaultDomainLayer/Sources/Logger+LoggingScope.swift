import Logging
import Foundation

private class IncrementingSequence: @unchecked Sendable {
    static let shared = IncrementingSequence()
    
    private let lock = NSLock()
    private var value: Int = 0
    
    func next() -> Int {
        lock.lock()
        defer {
            lock.unlock()
        }
        value += 1
        return value
    }
}

enum LoggingScope: CustomStringConvertible {
    enum Domain: CustomStringConvertible {
        case shared
        case sandbox
        case hosted
        
        var description: String {
            switch self {
            case .shared:
                "🧑‍💻"
            case .sandbox:
                "👩‍💼"
            case .hosted:
                nextHostedSessionDescription
            }
        }
        
        private var nextHostedSessionDescription: String {
            let values = ["👩‍💻", "👩🏻‍💻", "👩🏼‍💻", "👩🏽‍💻", "👩🏾‍💻", "👩🏿‍💻"]
            return values[IncrementingSequence.shared.next() % values.count]
        }
    }
    
    case dataLayer
    case domainLayer(Domain)
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
        case .domainLayer(let domain):
            domain.description
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
