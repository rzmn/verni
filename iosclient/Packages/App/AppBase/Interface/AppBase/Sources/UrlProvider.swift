import Entities
import Foundation
import Convenience

@Observable @MainActor public class UrlProvider: Sendable {
    private let schema: String
    
    public init(schema: String) {
        self.schema = schema
    }
    
    public nonisolated func url(for item: Item) -> URL? {
        switch item {
        case .users(let action):
            switch action {
            case .show(let user):
                return modify(URLComponents()) { components in
                    components.scheme = schema
                    components.host = Item.Host.userPreview
                    components.queryItems = [
                        Item.Key.user: user.id,
                        Item.Key.name: user.payload.displayName,
                        Item.Key.avatar: user.payload.avatar
                    ].compactMapValues { $0 }.map { (key: String, value: String) in
                        URLQueryItem(name: key, value: value)
                    }
                }.url
            }
        }
    }
    
    public nonisolated func item(for url: URL) -> Item? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        guard components.scheme == schema else {
            return nil
        }
        let value: (String) -> String? = { key in
            components.queryItems?.first { $0.name == key }?.value
        }
        switch components.host {
        case Item.Host.userPreview:
            guard let id = value(Item.Key.user), let name = value(Item.Key.name) else {
                return nil
            }
            return .users(
                .show(
                    User(
                        id: id,
                        payload: UserPayload(
                            displayName: name,
                            avatar: value(Item.Key.avatar)
                        )
                    )
                )
            )
        default:
            return nil
        }
    }
}

extension UrlProvider {
    public enum Item: Sendable {
        struct Host {
            static let userPreview = "u"
        }
        struct Key {
            static let user = "u"
            static let name = "n"
            static let avatar = "a"
        }

        public enum Users: Sendable {
            case show(User)
        }
        case users(Users)
    }
}
