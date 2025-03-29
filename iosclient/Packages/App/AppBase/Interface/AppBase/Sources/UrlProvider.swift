import Entities
import Foundation
import Convenience

@Observable @MainActor public class UrlProvider: Sendable {
    private let internalSchema: String
    private let publicHost: URL
    
    public init(schema: String, host: URL) {
        self.internalSchema = schema
        self.publicHost = host
    }
    
    public nonisolated func internalUrl(for item: Item) -> URL? {
        switch item {
        case .users(let action):
            switch action {
            case .show(let user):
                return modify(URLComponents()) { components in
                    components.scheme = internalSchema
                    components.host = Item.Base.userPreview
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
    
    public nonisolated func externalUrl(for item: Item) -> URL? {
        switch item {
        case .users(let action):
            switch action {
            case .show(let user):
                return modify(URLComponents()) { components in
                    components.scheme = publicHost.scheme
                    components.host = publicHost.host()
                    components.path = "/\(Item.Base.userPreview)"
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
        if let (host, components) = internalItem(for: url) {
            return item(base: host, components: components)
        }
        if let (host, components) = externalItem(for: url) {
            return item(base: host, components: components)
        }
        return nil
    }
    
    private nonisolated func internalItem(for url: URL) -> (host: String, components: (String) -> String?)? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        guard components.scheme == internalSchema else {
            return nil
        }
        guard let host = components.host else {
            return nil
        }
        return (
            host: host,
            components: { key in
                components.queryItems?.first { $0.name == key }?.value
            }
        )
    }
    
    private nonisolated func externalItem(for url: URL) -> (host: String, components: (String) -> String?)? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        guard let host = components.host else {
            return nil
        }
        guard host == publicHost.host() else {
            return nil
        }
        guard let base = url.pathComponents.last else {
            return nil
        }
        return (
            host: base,
            components: { key in
                components.queryItems?.first { $0.name == key }?.value
            }
        )
    }
    
    public nonisolated func item(base: String, components: (String) -> String?) -> Item? {
        switch base {
        case Item.Base.userPreview:
            guard let id = components(Item.Key.user), let name = components(Item.Key.name) else {
                return nil
            }
            return .users(
                .show(
                    User(
                        id: id,
                        payload: UserPayload(
                            displayName: name,
                            avatar: components(Item.Key.avatar)
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
        struct Base {
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
