import Entities
import Foundation
import Convenience

public enum AppUrl: Sendable {
    struct Host {
        static let userPreview = "u"
    }
    struct Key {
        static let user = "u"
        static let name = "n"
        static let avatar = "a"
    }
    
    private static var scheme: String {
        "verni"
    }

    public enum Users: Sendable {
        case show(User)
    }
    case users(Users)

    public var url: URL? {
        switch self {
        case .users(let action):
            switch action {
            case .show(let user):
                let components = modify(URLComponents()) { components in
                    components.scheme = Self.scheme
                    components.host = Host.userPreview
                    components.queryItems = [
                        Key.user: user.id,
                        Key.name: user.payload.displayName,
                        Key.avatar: user.payload.avatar
                    ].compactMapValues { $0 }.map { (key: String, value: String) in
                        URLQueryItem(name: key, value: value)
                    }
                }
                return components.url
            }
        }
    }

    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        guard components.scheme == Self.scheme else {
            return nil
        }
        let value: (String) -> String? = { key in
            components.queryItems?.first { $0.name == key }?.value
        }
        switch components.host {
        case Host.userPreview:
            guard let id = value(Key.user), let name = value(Key.name) else {
                return nil
            }
            self = .users(
                .show(
                    User(
                        id: id,
                        payload: UserPayload(
                            displayName: name,
                            avatar: value(Key.avatar)
                        )
                    )
                )
            )
        default:
            return nil
        }
    }
}
