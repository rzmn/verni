import Logging
import Foundation

public enum LoggingScope: CustomStringConvertible {
    case appLayer(App)
    case domainLayer(Domain)
    case dataLayer(Data)

    case api
    case saveCredentials
    case images
    case infrastructure
    case filesystem
    case database
    case sync
    case users
    case spendings
    case operations
    case profileEditing
    case addSpending
    case userPreview
    case auth
    case logIn
    case signUp
    case pushNotifications
    case emailConfirmation
    case qrCode
    case profile
    case logout
    
    public var description: String {
        switch self {
        case .appLayer(let app):
            app.description
        case .domainLayer(let domain):
            domain.description
        case .dataLayer(let data):
            data.description
        case .api:
            "⚡️"
        case .sync:
            "🔄"
        case .logIn:
            "👋"
        case .signUp:
            "👶"
        case .operations:
            "💎"
        case .saveCredentials:
            "🔐"
        case .images:
            "🧑‍🎨"
        case .infrastructure:
            "⚙️"
        case .profileEditing:
            "💅"
        case .filesystem:
            "📁"
        case .database:
            "🗄️"
        case .users:
            "🪪"
        case .spendings:
            "💸"
        case .addSpending:
            "🤑"
        case .auth:
            "🛂"
        case .pushNotifications:
            "🔔"
        case .emailConfirmation:
            "📧"
        case .userPreview:
            "👩‍🎤"
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
    public func with(scope: LoggingScope) -> Logger {
        with(prefix: scope.description)
    }
}

private class SessionCounter: @unchecked Sendable {
    static let data = SessionCounter()
    static let domain = SessionCounter()
    static let app = SessionCounter()
    
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

extension LoggingScope {
    public enum Data: CustomStringConvertible {
        case shared
        case sandbox
        case hosted
        
        public var description: String {
            switch self {
            case .shared, .sandbox:
                "👷‍♂️"
            case .hosted:
                nextHostedSessionDescription
            }
        }
        
        private var nextHostedSessionDescription: String {
            let values = ["👷🏻‍♀️", "👷🏼‍♀️", "👷🏽‍♀️", "👷🏾‍♀️", "👷🏿‍♀️", "👷‍♀️"]
            return values[SessionCounter.data.next() % values.count]
        }
    }
}

extension LoggingScope {
    public enum Domain: CustomStringConvertible {
        case shared
        case sandbox
        case hosted
        
        public var description: String {
            switch self {
            case .shared, .sandbox:
                "🧑‍💻"
            case .hosted:
                nextHostedSessionDescription
            }
        }
        
        private var nextHostedSessionDescription: String {
            let values = ["👩🏻‍💻", "👩🏼‍💻", "👩🏽‍💻", "👩🏾‍💻", "👩🏿‍💻", "👩‍💻"]
            return values[SessionCounter.domain.next() % values.count]
        }
    }
}

extension LoggingScope {
    public enum App: CustomStringConvertible {
        case shared
        case sandbox
        case hosted
        
        public var description: String {
            switch self {
            case .shared, .sandbox:
                "👨‍🎨"
            case .hosted:
                nextHostedSessionDescription
            }
        }
        
        private var nextHostedSessionDescription: String {
            let values = ["👩🏻‍🎨", "👩🏼‍🎨", "👩🏽‍🎨", "👩🏾‍🎨", "👩🏿‍🎨", "👩‍🎨"]
            return values[SessionCounter.domain.next() % values.count]
        }
    }
}
